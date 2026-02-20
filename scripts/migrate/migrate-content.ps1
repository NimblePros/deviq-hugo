<#
.SYNOPSIS
  Migrates Gatsby docs content into the Hugo site.
.DESCRIPTION
  Reads source markdown files from _reference/src/docs/{category}, converts frontmatter
  and internal links to Hugo/Hextra format, and copies to content/docs/{category}.
  Skips files already present unless -Overwrite is specified.
.PARAMETER Category
  The content category to migrate (e.g. "design-patterns", "principles"). Omit to migrate all.
.PARAMETER Limit
  Maximum number of files to migrate this run. 0 = no limit (default).
.PARAMETER DryRun
  Preview changes without writing any files.
.PARAMETER Overwrite
  Re-process files that have already been migrated.
.PARAMETER IncludeImages
  Also copy images from the source images/ subdirectory.
.EXAMPLE
  # Migrate all design-patterns (dry run first)
  ./migrate-content.ps1 -Category design-patterns -DryRun
  ./migrate-content.ps1 -Category design-patterns -IncludeImages

  # Migrate everything in batches of 25
  ./migrate-content.ps1 -Limit 25

  # Overwrite already-migrated files in a specific category
  ./migrate-content.ps1 -Category principles -Overwrite -IncludeImages
#>
[CmdletBinding()]
param(
    [string]$Category,
    [int]$Limit = 0,
    [switch]$DryRun,
    [switch]$Overwrite,
    [switch]$IncludeImages
)

$ErrorActionPreference = "Stop"

# Resolve repo root (two levels up from this script: scripts/migrate -> scripts -> root)
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..") | Select-Object -ExpandProperty Path

$sourceBase = Join-Path $repoRoot "_reference\src\docs"
$destBase   = Join-Path $repoRoot "content\docs"

if (-not (Test-Path $sourceBase)) {
    Write-Error "Source directory not found: $sourceBase"
    exit 1
}
if (-not (Test-Path $destBase)) {
    Write-Error "Destination directory not found: $destBase. Run hugo new content/docs/ first."
    exit 1
}

# All valid categories
$allCategories = @(
    "antipatterns", "architecture", "code-smells", "design-patterns",
    "domain-driven-design", "laws", "practices", "principles",
    "terms", "testing", "tools", "values"
)

$categoriesToProcess = if ($Category) { @($Category) } else { $allCategories }

# --- Frontmatter helpers ---

function Get-FrontMatterLines {
    param([string[]]$Lines)
    if ($Lines[0].Trim() -ne '---') { return $null, -1 }
    $end = 1
    while ($end -lt $Lines.Length -and $Lines[$end].Trim() -ne '---') { $end++ }
    if ($end -ge $Lines.Length) { return $null, -1 }
    return $Lines[1..($end - 1)], $end
}

function Parse-FrontMatter {
    param([string[]]$Lines)
    $data = [ordered]@{}
    $i = 0
    while ($i -lt $Lines.Length) {
        $ln = $Lines[$i]
        if ($ln -match '^(\s*#.*|\s*)$') { $i++; continue }
        if ($ln -match '^(?<k>[A-Za-z][A-Za-z0-9_-]*):\s*(?<v>.*)$') {
            $k = $Matches.k.Trim()
            $v = $Matches.v.Trim()
            # Strip surrounding quotes
            if (($v -match '^".*"$') -or ($v -match "^'.*'$")) {
                $v = $v.Substring(1, $v.Length - 2)
            }
            $data[$k] = $v
        }
        $i++
    }
    return $data
}

function Convert-FrontMatter {
    param(
        [hashtable]$Parsed,
        [string]$Category,
        [string]$Slug
    )
    $out = [ordered]@{}

    # title: keep as-is
    if ($Parsed.title) { $out.title = $Parsed.title }
    else { $out.title = $Slug -replace '-', ' ' }

    # date: remove quotes
    if ($Parsed.date) { $out.date = $Parsed.date -replace '"', '' -replace "'", '' }

    # description: keep as-is
    if ($Parsed.description) { $out.description = $Parsed.description }

    # weight: derive from alphabetical order; caller may override
    # Leave as placeholder - the setup-structure script sets per-section weights
    # For now, omit weight (Hextra auto-orders alphabetically)

    # featuredImage -> params.image (absolute Hugo path)
    if ($Parsed.featuredImage -or $Parsed.featuredimage) {
        $fi = if ($Parsed.featuredImage) { $Parsed.featuredImage } else { $Parsed.featuredimage }
        # Convert "./images/foo.png" -> "/docs/{category}/images/foo.png"
        $imgFile = $fi -replace '^\./', '' -replace '^/', ''
        $out['params'] = @{ image = "/docs/$Category/$imgFile" }
    }

    return $out
}

function ConvertTo-YamlText {
    param($Hash)
    $sb = New-Object System.Text.StringBuilder
    foreach ($k in $Hash.Keys) {
        $v = $Hash[$k]
        if ($v -is [hashtable] -or $v -is [System.Collections.Specialized.OrderedDictionary]) {
            [void]$sb.AppendLine("${k}:")
            foreach ($nested in $v.Keys) {
                $nv = $v[$nested]
                [void]$sb.AppendLine("  ${nested}: $nv")
            }
        } elseif ($v -is [boolean]) {
            [void]$sb.AppendLine("${k}: " + $v.ToString().ToLower())
        } else {
            # Quote values that contain colons or leading/trailing whitespace
            if ($v -match '^\s|\s$' -or ($v -match ':' -and $v -notmatch '^http')) {
                $v = '"' + ($v -replace '"', '\"') + '"'
            }
            [void]$sb.AppendLine("${k}: $v")
        }
    }
    return $sb.ToString().TrimEnd()
}

# --- Link transformation ---

function Convert-InternalLinks {
    param([string]$Content)
    # Convert bare Gatsby internal links to Hugo /docs/ paths
    # Pattern: [text](/category/slug) -> [text](/docs/category/slug/)
    # Only match known category paths to avoid false positives
    $knownCats = "antipatterns|architecture|code-smells|design-patterns|domain-driven-design|laws|practices|principles|terms|testing|tools|values"
    $Content = [regex]::Replace($Content,
        "\]\(/($knownCats)/([\w-]+)(/?)?\)",
        { param($m) "]( /docs/$($m.Groups[1].Value)/$($m.Groups[2].Value)/)" })
    # Remove the space we added after ]( to avoid URL encoding issues
    $Content = $Content -replace '\]\( /', ']( /' -replace '\]\( /', ']('
    # Redo without the extra space
    $Content = [regex]::Replace($Content,
        "\]\(/($knownCats)/([\w-]+)(/?)?\)",
        { param($m) "](/docs/$($m.Groups[1].Value)/$($m.Groups[2].Value)/)" })
    return $Content
}

# --- Main migration loop ---

$totalCreated  = 0
$totalSkipped  = 0
$totalErrors   = 0

foreach ($cat in $categoriesToProcess) {
    $sourceDir = Join-Path $sourceBase $cat
    $destDir   = Join-Path $destBase $cat

    if (-not (Test-Path $sourceDir)) {
        Write-Warning "Source category not found, skipping: $sourceDir"
        continue
    }

    $mdFiles = Get-ChildItem -Path $sourceDir -Filter "*.md" -File | Sort-Object Name
    if (-not $mdFiles) {
        Write-Warning "No markdown files in: $sourceDir"
        continue
    }

    # Ensure destination directory exists
    if (-not $DryRun -and -not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        Write-Host "  Created directory: $destDir" -ForegroundColor DarkGray
    }

    Write-Host "`nCategory: $cat ($($mdFiles.Count) files)" -ForegroundColor Cyan

    $processed = 0
    foreach ($file in $mdFiles) {
        if ($Limit -gt 0 -and ($totalCreated + $totalSkipped) -ge $Limit) { break }

        $slug = $file.BaseName
        $destFile = Join-Path $destDir "$slug.md"

        if ((Test-Path $destFile) -and -not $Overwrite) {
            Write-Host "  [SKIP] $slug" -ForegroundColor DarkYellow
            $totalSkipped++
            continue
        }

        try {
            $raw   = Get-Content -Path $file.FullName -Raw -Encoding UTF8
            $lines = $raw -replace "\r", "" -split "`n"

            $fmLines, $fmEnd = Get-FrontMatterLines -Lines $lines
            if ($null -eq $fmLines) {
                Write-Warning "  [WARN] No frontmatter found in $($file.Name), copying as-is"
                if (-not $DryRun) { Copy-Item $file.FullName $destFile -Force }
                $totalCreated++
                continue
            }

            $parsed   = Parse-FrontMatter -Lines $fmLines
            $newFront = Convert-FrontMatter -Parsed $parsed -Category $cat -Slug $slug
            $yaml     = ConvertTo-YamlText -Hash $newFront

            $body = ($lines[($fmEnd + 1)..($lines.Length - 1)]) -join "`n"
            $body = Convert-InternalLinks -Content $body
            $body = $body.Trim()

            $output = "---`n$yaml`n---`n`n$body`n"

            if ($DryRun) {
                Write-Host "  [WOULD CREATE] $destFile" -ForegroundColor Magenta
                Write-Host "    Frontmatter keys: $($newFront.Keys -join ', ')" -ForegroundColor DarkGray
            } else {
                $parentDir = Split-Path $destFile -Parent
                if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
                [System.IO.File]::WriteAllText($destFile, ($output -replace "`n", [System.Environment]::NewLine), [System.Text.Encoding]::UTF8)
                Write-Host "  [OK] $slug" -ForegroundColor Green
            }
            $totalCreated++
        } catch {
            Write-Host "  [ERR] $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
            $totalErrors++
        }

        $processed++
    }

    # Copy images if requested
    if ($IncludeImages) {
        $sourceImages = Join-Path $sourceDir "images"
        $destImages   = Join-Path $destDir "images"
        if (Test-Path $sourceImages) {
            $imgFiles = Get-ChildItem -Path $sourceImages -File
            if ($imgFiles) {
                if (-not $DryRun -and -not (Test-Path $destImages)) {
                    New-Item -ItemType Directory -Path $destImages -Force | Out-Null
                }
                foreach ($img in $imgFiles) {
                    $imgDest = Join-Path $destImages $img.Name
                    if ((Test-Path $imgDest) -and -not $Overwrite) {
                        Write-Host "  [SKIP IMG] $($img.Name)" -ForegroundColor DarkYellow
                    } else {
                        if ($DryRun) {
                            Write-Host "  [WOULD COPY IMG] $($img.Name)" -ForegroundColor Magenta
                        } else {
                            Copy-Item $img.FullName $imgDest -Force
                            Write-Host "  [IMG] $($img.Name)" -ForegroundColor DarkGreen
                        }
                    }
                }
            }
        }
    }
}

Write-Host "`nDone. Created/updated: $totalCreated  Skipped: $totalSkipped  Errors: $totalErrors" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "Dry run - no files were written. Remove -DryRun to apply." -ForegroundColor Yellow
}
