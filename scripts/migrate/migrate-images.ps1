<#
.SYNOPSIS
  Copies images from the Gatsby reference source to content/docs destination directories.
.DESCRIPTION
  Migrates images from _reference/src/docs/{category}/images/ to
  content/docs/{category}/images/ so they are co-located with the Hugo page bundles.
  Skips images that already exist at the destination unless -Overwrite is set.
.PARAMETER Category
  Limit migration to a specific category (e.g. "design-patterns"). Omit to process all.
.PARAMETER DryRun
  Preview which files would be copied without actually copying anything.
.PARAMETER Overwrite
  Overwrite destination images that already exist.
.EXAMPLE
  # Preview what would be copied
  ./migrate-images.ps1 -DryRun

  # Copy images for a single category
  ./migrate-images.ps1 -Category design-patterns

  # Copy all images, overwriting existing
  ./migrate-images.ps1 -Overwrite
#>
[CmdletBinding()]
param(
    [string]$Category,
    [switch]$DryRun,
    [switch]$Overwrite
)

$ErrorActionPreference = "Stop"

$repoRoot   = Resolve-Path (Join-Path $PSScriptRoot "..\..") | Select-Object -ExpandProperty Path
$sourceBase = Join-Path $repoRoot "_reference\src\docs"
$destBase   = Join-Path $repoRoot "content\docs"

if (-not (Test-Path $sourceBase)) {
    Write-Error "Source not found: $sourceBase"
    exit 1
}

$allCategories = @(
    "antipatterns", "architecture", "code-smells", "design-patterns",
    "domain-driven-design", "laws", "practices", "principles",
    "terms", "testing", "tools", "values"
)

$categoriesToProcess = if ($Category) { @($Category) } else { $allCategories }

$totalCopied  = 0
$totalSkipped = 0
$totalMissing = 0

foreach ($cat in $categoriesToProcess) {
    $sourceImages = Join-Path $sourceBase "$cat\images"
    $destImages   = Join-Path $destBase "$cat\images"

    if (-not (Test-Path $sourceImages)) {
        Write-Host "[$cat] No images/ directory found - skipping" -ForegroundColor DarkYellow
        continue
    }

    $imgFiles = Get-ChildItem -Path $sourceImages -File | Where-Object {
        $_.Extension -match '\.(png|jpg|jpeg|gif|webp|svg|avif)$'
    }

    if (-not $imgFiles) {
        Write-Host "[$cat] No image files found" -ForegroundColor DarkYellow
        continue
    }

    Write-Host "`n[$cat] Found $($imgFiles.Count) image(s)" -ForegroundColor Cyan

    # Ensure destination directory exists
    if (-not $DryRun -and -not (Test-Path $destImages)) {
        New-Item -ItemType Directory -Path $destImages -Force | Out-Null
        Write-Host "  Created: $destImages" -ForegroundColor DarkGray
    }

    foreach ($img in $imgFiles) {
        $destFile = Join-Path $destImages $img.Name

        if ((Test-Path $destFile) -and -not $Overwrite) {
            Write-Host "  [SKIP] $($img.Name)" -ForegroundColor DarkYellow
            $totalSkipped++
            continue
        }

        if ($DryRun) {
            Write-Host "  [WOULD COPY] $($img.Name) -> $destFile" -ForegroundColor Magenta
        } else {
            Copy-Item $img.FullName $destFile -Force
            Write-Host "  [COPY] $($img.Name)" -ForegroundColor Green
        }
        $totalCopied++
    }
}

# Report any content/docs markdown files whose referenced images are missing
Write-Host "`nChecking for missing image references in content/docs..." -ForegroundColor Cyan
$allMd = Get-ChildItem -Path $destBase -Filter "*.md" -Recurse -File
$missingRefs = @()

foreach ($md in $allMd) {
    $content = Get-Content $md.FullName -Raw -Encoding UTF8
    # Find image references in markdown body
    $matches = [regex]::Matches($content, '!\[.*?\]\((images/[^)]+)\)')
    foreach ($m in $matches) {
        $imgPath = $m.Groups[1].Value
        $fullImgPath = Join-Path (Split-Path $md.FullName -Parent) $imgPath
        if (-not (Test-Path $fullImgPath)) {
            $missingRefs += [pscustomobject]@{
                File  = $md.FullName -replace [regex]::Escape($repoRoot), ''
                Image = $imgPath
            }
            $totalMissing++
        }
    }
}

if ($missingRefs) {
    Write-Host "`nMissing image references:" -ForegroundColor Red
    $missingRefs | Format-Table -AutoSize
} else {
    Write-Host "  All referenced images found." -ForegroundColor Green
}

Write-Host "`nSummary: Copied=$totalCopied  Skipped=$totalSkipped  MissingRefs=$totalMissing" -ForegroundColor Cyan
if ($DryRun) { Write-Host "Dry run - no files were written." -ForegroundColor Yellow }
