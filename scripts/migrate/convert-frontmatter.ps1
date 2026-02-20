<#
.SYNOPSIS
  Converts frontmatter in already-migrated Hugo docs files from Gatsby format to Hugo/Hextra format.
.DESCRIPTION
  Use this script to re-process frontmatter in content/docs without re-copying the body content.
  Useful for bulk corrections after files have already been moved.
  Transformations applied:
    - Remove quotes from date values
    - Convert featuredImage "./images/foo.png" -> params.image: /docs/{category}/images/foo.png
    - Remove featuredImage field if -RemoveFeaturedImage is set
    - Add weight field if -AddWeight is set
.PARAMETER Path
  Path to a specific .md file, or a directory to process recursively. Defaults to content/docs.
.PARAMETER DryRun
  Show what would change without modifying files.
.PARAMETER RemoveFeaturedImage
  Drop the featuredImage field entirely instead of converting to params.image.
.PARAMETER AddWeight
  Add a weight field based on alphabetical sort order within each section directory.
.EXAMPLE
  # Preview changes for all docs
  ./convert-frontmatter.ps1 -DryRun

  # Apply to a single category
  ./convert-frontmatter.ps1 -Path content/docs/principles

  # Apply with weight ordering
  ./convert-frontmatter.ps1 -AddWeight
#>
[CmdletBinding()]
param(
    [string]$Path,
    [switch]$DryRun,
    [switch]$RemoveFeaturedImage,
    [switch]$AddWeight
)

$ErrorActionPreference = "Stop"

$repoRoot   = Resolve-Path (Join-Path $PSScriptRoot "..\..") | Select-Object -ExpandProperty Path
$docsRoot   = Join-Path $repoRoot "content\docs"

$targetPath = if ($Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path $repoRoot $Path }
} else {
    $docsRoot
}

if (-not (Test-Path $targetPath)) {
    Write-Error "Path not found: $targetPath"
    exit 1
}

# Collect files
$mdFiles = if (Test-Path $targetPath -PathType Container) {
    Get-ChildItem -Path $targetPath -Filter "*.md" -Recurse -File
} else {
    @(Get-Item $targetPath)
}

if (-not $mdFiles) {
    Write-Warning "No .md files found at: $targetPath"
    exit 0
}

# Build weight map per directory (alphabetical order, starting at 10, step 10)
$weightMaps = @{}
if ($AddWeight) {
    $byDir = $mdFiles | Group-Object { Split-Path $_.FullName -Parent }
    foreach ($grp in $byDir) {
        $sorted = $grp.Group | Sort-Object Name
        $map = @{}
        $w = 10
        foreach ($f in $sorted) {
            $map[$f.FullName] = $w
            $w += 10
        }
        $weightMaps[$grp.Name] = $map
    }
}

function Get-CategoryFromPath {
    param([string]$FilePath)
    # Extract category from path like content/docs/{category}/...
    $rel = $FilePath -replace [regex]::Escape($docsRoot), '' -replace '^[/\\]+', ''
    $parts = $rel -split '[/\\]'
    if ($parts.Length -ge 1) { return $parts[0] } else { return '' }
}

$changed  = 0
$unchanged = 0
$errors   = 0

foreach ($file in $mdFiles) {
    try {
        $raw   = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        $lines = $raw -replace "\r", "" -split "`n"

        if ($lines[0].Trim() -ne '---') { $unchanged++; continue }

        $fmEnd = 1
        while ($fmEnd -lt $lines.Length -and $lines[$fmEnd].Trim() -ne '---') { $fmEnd++ }
        if ($fmEnd -ge $lines.Length) { $unchanged++; continue }

        $fmLines = $lines[1..($fmEnd - 1)]
        $body    = ($lines[($fmEnd + 1)..($lines.Length - 1)]) -join "`n"

        $category = Get-CategoryFromPath -FilePath $file.FullName

        # Parse and transform
        $newFmLines = [System.Collections.Generic.List[string]]::new()
        $inParams   = $false
        $modified   = $false

        foreach ($ln in $fmLines) {
            # date: remove quotes
            if ($ln -match '^date:\s*["\x27](.+)["\x27]\s*$') {
                $newFmLines.Add("date: $($Matches[1])")
                $modified = $true
                continue
            }

            # featuredImage / featuredimage
            if ($ln -match '^featuredImage:\s*(.+)$' -or $ln -match '^featuredimage:\s*(.+)$') {
                if ($RemoveFeaturedImage) {
                    $modified = $true
                    continue  # drop the line
                }
                $fi = $Matches[1].Trim() -replace '^["\x27]', '' -replace '["\x27]$', ''
                $imgFile = $fi -replace '^\./', '' -replace '^/', ''
                if ($category) {
                    $newFmLines.Add("params:")
                    $newFmLines.Add("  image: /docs/$category/$imgFile")
                    $modified = $true
                } else {
                    $newFmLines.Add($ln)
                }
                continue
            }

            $newFmLines.Add($ln)
        }

        # Inject weight if requested and not already present
        if ($AddWeight -and -not ($newFmLines -match '^weight:')) {
            $dirKey = Split-Path $file.FullName -Parent
            if ($weightMaps.ContainsKey($dirKey) -and $weightMaps[$dirKey].ContainsKey($file.FullName)) {
                $w = $weightMaps[$dirKey][$file.FullName]
                $newFmLines.Add("weight: $w")
                $modified = $true
            }
        }

        if (-not $modified) { $unchanged++; continue }

        $newFm   = ($newFmLines -join "`n")
        $output  = "---`n$newFm`n---`n`n$($body.Trim())`n"
        $output  = $output -replace "`n", [System.Environment]::NewLine

        if ($DryRun) {
            Write-Host "[DRY RUN] Would update: $($file.FullName)" -ForegroundColor Magenta
            $changed++
        } else {
            [System.IO.File]::WriteAllText($file.FullName, $output, [System.Text.Encoding]::UTF8)
            Write-Host "[OK] $($file.FullName)" -ForegroundColor Green
            $changed++
        }
    } catch {
        Write-Host "[ERR] $($file.FullName): $($_.Exception.Message)" -ForegroundColor Red
        $errors++
    }
}

Write-Host "`nDone. Modified: $changed  Unchanged: $unchanged  Errors: $errors" -ForegroundColor Cyan
if ($DryRun) { Write-Host "Dry run - no files were written." -ForegroundColor Yellow }
