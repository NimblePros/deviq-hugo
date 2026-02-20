<#
.SYNOPSIS
  Validates internal links in migrated Hugo docs content.
.DESCRIPTION
  Scans all markdown files under content/docs for internal links and checks that their
  targets resolve to actual files on disk. Reports broken links so they can be fixed
  before or after running `hugo build`.

  Also checks for:
  - Old Gatsby-style links (missing /docs/ prefix) that still need conversion
  - Image references that point to missing files
.PARAMETER Path
  Directory to scan. Defaults to content/docs.
.PARAMETER CheckImages
  Also validate image references (![alt](path)).
.PARAMETER GatsbyLinksOnly
  Only report links that look like unconverted Gatsby paths (missing /docs/ prefix).
.EXAMPLE
  # Validate all internal links in docs
  ./validate-links.ps1

  # Validate links and image references
  ./validate-links.ps1 -CheckImages

  # Find only unconverted Gatsby-style links
  ./validate-links.ps1 -GatsbyLinksOnly
#>
[CmdletBinding()]
param(
    [string]$Path,
    [switch]$CheckImages,
    [switch]$GatsbyLinksOnly
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..") | Select-Object -ExpandProperty Path
$docsRoot = Join-Path $repoRoot "content\docs"

$scanPath = if ($Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) { $Path } else { Join-Path $repoRoot $Path }
} else {
    $docsRoot
}

if (-not (Test-Path $scanPath)) {
    Write-Error "Path not found: $scanPath"
    exit 1
}

$knownCats = @(
    "antipatterns", "architecture", "code-smells", "design-patterns",
    "domain-driven-design", "laws", "practices", "principles",
    "terms", "testing", "tools", "values"
)
$knownCatPattern = $knownCats -join "|"

$mdFiles = Get-ChildItem -Path $scanPath -Filter "*.md" -Recurse -File

$brokenLinks     = [System.Collections.Generic.List[pscustomobject]]::new()
$gatsbyLinks     = [System.Collections.Generic.List[pscustomobject]]::new()
$brokenImages    = [System.Collections.Generic.List[pscustomobject]]::new()
$totalLinksCheck = 0
$totalImgCheck   = 0

foreach ($file in $mdFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $relFile = $file.FullName -replace [regex]::Escape($repoRoot), '' -replace '^[/\\]', ''

    # --- Check internal /docs/ links ---
    $linkMatches = [regex]::Matches($content, '\]\((/docs/[^\)#\s]+)')
    foreach ($m in $linkMatches) {
        $linkPath = $m.Groups[1].Value.TrimEnd('/')
        $totalLinksCheck++

        # Map /docs/{category}/{slug} to content/docs/{category}/{slug}.md or _index.md
        $rel = $linkPath -replace '^/docs/', ''
        $parts = $rel -split '/'
        $candidate1 = Join-Path $docsRoot ($parts -join '\') + ".md"
        $candidate2 = Join-Path $docsRoot ($parts -join '\') + "\_index.md"

        if (-not (Test-Path $candidate1) -and -not (Test-Path $candidate2)) {
            $brokenLinks.Add([pscustomobject]@{
                File = $relFile
                Link = $linkPath
            })
        }
    }

    # --- Check for old Gatsby-style links (not yet converted) ---
    $gatsbyMatches = [regex]::Matches($content, "\]\(/($knownCatPattern)/([\w-]+)/?\)")
    foreach ($m in $gatsbyMatches) {
        $gatsbyLinks.Add([pscustomobject]@{
            File       = $relFile
            GatsbyLink = "/$($m.Groups[1].Value)/$($m.Groups[2].Value)"
            HugoLink   = "/docs/$($m.Groups[1].Value)/$($m.Groups[2].Value)/"
        })
    }

    # --- Check image references ---
    if ($CheckImages) {
        $imgMatches = [regex]::Matches($content, '!\[.*?\]\((images/[^)]+)\)')
        foreach ($m in $imgMatches) {
            $imgRel = $m.Groups[1].Value
            $imgFull = Join-Path (Split-Path $file.FullName -Parent) $imgRel
            $totalImgCheck++
            if (-not (Test-Path $imgFull)) {
                $brokenImages.Add([pscustomobject]@{
                    File  = $relFile
                    Image = $imgRel
                })
            }
        }
    }
}

# --- Output ---

if ($GatsbyLinksOnly) {
    if ($gatsbyLinks.Count -eq 0) {
        Write-Host "No unconverted Gatsby-style links found." -ForegroundColor Green
    } else {
        Write-Host "`nUnconverted Gatsby links ($($gatsbyLinks.Count)):" -ForegroundColor Yellow
        $gatsbyLinks | Format-Table -AutoSize
        Write-Host "Run migrate-content.ps1 -Overwrite or convert-frontmatter.ps1 to fix these." -ForegroundColor Yellow
    }
    exit 0
}

if ($brokenLinks.Count -eq 0 -and $gatsbyLinks.Count -eq 0 -and $brokenImages.Count -eq 0) {
    Write-Host "All links valid. Files checked: $($mdFiles.Count)  Links: $totalLinksCheck" -ForegroundColor Green
    exit 0
}

if ($brokenLinks.Count -gt 0) {
    Write-Host "`nBroken /docs/ links ($($brokenLinks.Count)):" -ForegroundColor Red
    $brokenLinks | Format-Table -AutoSize
}

if ($gatsbyLinks.Count -gt 0) {
    Write-Host "`nUnconverted Gatsby links ($($gatsbyLinks.Count)) - these need /docs/ prefix:" -ForegroundColor Yellow
    $gatsbyLinks | Format-Table -AutoSize
}

if ($CheckImages -and $brokenImages.Count -gt 0) {
    Write-Host "`nBroken image references ($($brokenImages.Count)):" -ForegroundColor Red
    $brokenImages | Format-Table -AutoSize
}

Write-Host "`nSummary: Files=$($mdFiles.Count)  LinksChecked=$totalLinksCheck  BrokenLinks=$($brokenLinks.Count)  GatsbyLinks=$($gatsbyLinks.Count)  BrokenImages=$($brokenImages.Count)" -ForegroundColor Cyan

if ($brokenLinks.Count -gt 0 -or $brokenImages.Count -gt 0) { exit 1 } else { exit 0 }
