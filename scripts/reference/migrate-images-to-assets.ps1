<#
.SYNOPSIS
    Migrates images from static/img to assets/img for Hugo image processing
.DESCRIPTION
    This script copies images from static/img to assets/img so Hugo can automatically
    generate WebP versions and responsive sizes. Keeps originals in static as fallback.
.PARAMETER ImagePattern
    Pattern to match images (default: *.jpg, *.png, *.jpeg)
.PARAMETER CopyAll
    Copy all images (default: false, only copies featured images from blog posts)
.PARAMETER DryRun
    Show what would be migrated without actually copying files
#>

param(
    [string]$ImagePattern = "*",
    [switch]$CopyAll,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Ensure we're in the Hugo root directory
$hugoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $hugoRoot

try {
    # Create assets/img directory if it doesn't exist
    $assetsImg = Join-Path $hugoRoot "assets\img"
    if (-not (Test-Path $assetsImg)) {
        Write-Host "Creating assets/img directory..." -ForegroundColor Green
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $assetsImg -Force | Out-Null
        }
    }

    $staticImg = Join-Path $hugoRoot "static\img"
    
    if ($CopyAll) {
        # Copy all matching images
        $images = Get-ChildItem -Path $staticImg -Filter $ImagePattern -File | 
        Where-Object { $_.Extension -match '\.(jpg|jpeg|png|webp)$' }
        
        Write-Host "Found $($images.Count) images matching pattern '$ImagePattern'" -ForegroundColor Cyan
        
        foreach ($img in $images) {
            $destPath = Join-Path $assetsImg $img.Name
            if (Test-Path $destPath) {
                Write-Host "  [SKIP] $($img.Name) (already exists in assets)" -ForegroundColor Yellow
            }
            else {
                Write-Host "  [COPY] $($img.Name)" -ForegroundColor Green
                if (-not $DryRun) {
                    Copy-Item $img.FullName $destPath
                }
            }
        }
    }
    else {
        # Extract featured images from blog posts
        $contentDir = Join-Path $hugoRoot "content\blog"
        $mdFiles = Get-ChildItem -Path $contentDir -Filter "*.md" -File
        
        $featuredImages = @{}
        
        Write-Host "Scanning $($mdFiles.Count) blog posts for featured images..." -ForegroundColor Cyan
        
        foreach ($mdFile in $mdFiles) {
            $content = Get-Content $mdFile.FullName -Raw
            if ($content -match 'featuredImage:\s*["'']?(/img/|img/)([^"''\s]+)') {
                $imgName = $matches[2]
                if (-not $featuredImages.ContainsKey($imgName)) {
                    $featuredImages[$imgName] = @()
                }
                $featuredImages[$imgName] += $mdFile.Name
            }
        }
        
        Write-Host "Found $($featuredImages.Count) unique featured images" -ForegroundColor Cyan
        
        # Also include hero images from templates
        $heroImages = @(
            "ardalis-techorama-2024.jpg"
        )
        
        foreach ($heroImg in $heroImages) {
            $featuredImages[$heroImg] = $true
        }
        
        # Copy featured images to assets
        $copied = 0
        $skipped = 0
        $notFound = 0
        $missingImages = @()
        
        foreach ($imgName in $featuredImages.Keys) {
            $sourcePath = Join-Path $staticImg $imgName
            $destPath = Join-Path $assetsImg $imgName
            
            if (-not (Test-Path $sourcePath)) {
                # Also check if it already exists in assets (just not in static)
                if (Test-Path $destPath) {
                    Write-Host "  [OK]   $imgName (exists in assets, not in static)" -ForegroundColor DarkGray
                    $skipped++
                    continue
                }
                Write-Host "  [MISS] $imgName (not found in static/img or assets/img)" -ForegroundColor Red
                $missingImages += [pscustomobject]@{
                    Image = $imgName
                    ReferencedBy = $featuredImages[$imgName] -join ', '
                }
                $notFound++
                continue
            }
            
            if (Test-Path $destPath) {
                Write-Host "  [SKIP] $imgName (already in assets)" -ForegroundColor Yellow
                $skipped++
            }
            else {
                Write-Host "  [COPY] $imgName" -ForegroundColor Green
                if (-not $DryRun) {
                    Copy-Item $sourcePath $destPath
                }
                $copied++
            }
        }
        
        Write-Host "`nSummary:" -ForegroundColor Cyan
        Write-Host "  Copied: $copied" -ForegroundColor Green
        Write-Host "  Skipped (already exists): $skipped" -ForegroundColor Yellow
        Write-Host "  Not found: $notFound" -ForegroundColor $(if ($notFound -gt 0) { 'Red' } else { 'Green' })
        
        if ($missingImages.Count -gt 0) {
            Write-Host "`nMissing images (not in static/img or assets/img):" -ForegroundColor Red
            foreach ($m in $missingImages) {
                Write-Host "  $($m.Image)" -ForegroundColor Red
                Write-Host "    Referenced by: $($m.ReferencedBy)" -ForegroundColor Gray
            }
            Write-Host "`nThese images are referenced in frontmatter but don't exist on disk." -ForegroundColor Yellow
            Write-Host "You may need to create or download them, then run:" -ForegroundColor Yellow
            Write-Host "  .\scripts\optimize-image.ps1 -ImagePath <path>" -ForegroundColor White
        }
    }
    
    if ($DryRun) {
        Write-Host "`n[DRY RUN] No files were actually copied. Run without -DryRun to migrate." -ForegroundColor Magenta
    }
    else {
        Write-Host "`nImages migrated to assets/img. Hugo will now automatically generate optimized versions." -ForegroundColor Green
        Write-Host "Original images remain in static/img as fallback." -ForegroundColor Cyan
    }
    
}
finally {
    Pop-Location
}
