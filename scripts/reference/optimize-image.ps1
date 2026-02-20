<#
.SYNOPSIS
    Optimizes and adds a new image for blog posts
.DESCRIPTION
    This script helps you add images with automatic optimization. Simply drop your
    image file and it will be added to assets/img where Hugo will automatically
    generate WebP and responsive versions.
.PARAMETER ImagePath
    Path to the image file to optimize
.PARAMETER OutputName
    Optional: Custom name for the output file (default: uses original name)
.EXAMPLE
    .\scripts\optimize-image.ps1 -ImagePath "C:\Downloads\my-screenshot.png"
.EXAMPLE
    .\scripts\optimize-image.ps1 -ImagePath "my-image.jpg" -OutputName "clean-architecture-diagram.jpg"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ImagePath,
    
    [string]$OutputName
)

$ErrorActionPreference = "Stop"

# Ensure we're in the Hugo root directory
$hugoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $hugoRoot

try {
    # Validate image exists
    if (-not (Test-Path $ImagePath)) {
        Write-Error "Image file not found: $ImagePath"
        exit 1
    }
    
    $imageFile = Get-Item $ImagePath
    
    # Validate it's an image
    if ($imageFile.Extension -notmatch '\.(jpg|jpeg|png|webp|gif)$') {
        Write-Error "File must be an image (jpg, jpeg, png, webp, or gif)"
        exit 1
    }
    
    # Determine output name
    if ([string]::IsNullOrWhiteSpace($OutputName)) {
        $OutputName = $imageFile.Name
    }
    
    # Sanitize output name (lowercase, replace spaces with hyphens, remove special chars except extension)
    $extension = [System.IO.Path]::GetExtension($OutputName)
    $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($OutputName)
    $nameWithoutExt = $nameWithoutExt.ToLower() -replace '\s+', '-' -replace '[^a-z0-9-]', ''
    $OutputName = "$nameWithoutExt$extension"
    
    # Create assets/img directory if it doesn't exist
    $assetsImg = Join-Path $hugoRoot "assets\img"
    if (-not (Test-Path $assetsImg)) {
        Write-Host "Creating assets/img directory..." -ForegroundColor Green
        New-Item -ItemType Directory -Path $assetsImg -Force | Out-Null
    }
    
    # Also create static/img as fallback
    $staticImg = Join-Path $hugoRoot "static\img"
    if (-not (Test-Path $staticImg)) {
        New-Item -ItemType Directory -Path $staticImg -Force | Out-Null
    }
    
    $assetsDestPath = Join-Path $assetsImg $OutputName
    $staticDestPath = Join-Path $staticImg $OutputName
    
    # Copy to assets (for Hugo processing)
    Write-Host "Copying to assets/img/$OutputName..." -ForegroundColor Cyan
    Copy-Item $imageFile.FullName $assetsDestPath -Force
    
    # Also copy to static as fallback
    Write-Host "Copying to static/img/$OutputName (fallback)..." -ForegroundColor Cyan
    Copy-Item $imageFile.FullName $staticDestPath -Force
    
    Write-Host "`nSuccess! Image ready to use." -ForegroundColor Green
    Write-Host "`nIn your blog post front matter, add:" -ForegroundColor Cyan
    Write-Host "  featuredImage: /img/$OutputName" -ForegroundColor White
    Write-Host "`nOr in your markdown content:" -ForegroundColor Cyan
    Write-Host "  ![Description](/img/$OutputName)" -ForegroundColor White
    
    # Generate Hugo optimized versions
    Write-Host "`nGenerating optimized WebP and responsive versions..." -ForegroundColor Yellow
    
    # Try to find hugo executable
    $hugoCmd = $null
    if (Get-Command hugo -ErrorAction SilentlyContinue) {
        $hugoCmd = "hugo"
    } else {
        # Check winget installation location
        $wingetHugo = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Hugo.Hugo.Extended_Microsoft.Winget.Source_8wekyb3d8bbwe\hugo.exe"
        if (Test-Path $wingetHugo) {
            $hugoCmd = $wingetHugo
        }
    }
    
    if ($hugoCmd) {
        & $hugoCmd --quiet
        Write-Host "Optimized versions generated in resources/_gen/images/" -ForegroundColor Green
        Write-Host "These files are committed to git for faster Cloudflare builds." -ForegroundColor Cyan
    } else {
        Write-Host "Hugo not found. Run .\build.ps1 -Production to generate optimized versions." -ForegroundColor Yellow
    }
    
    Write-Host "`nHugo automatically:" -ForegroundColor Yellow
    Write-Host "  * Generate WebP versions (60-80% smaller)" -ForegroundColor Green
    Write-Host "  * Create responsive sizes (400px, 800px, 1200px, 1600px)" -ForegroundColor Green
    Write-Host "  * Add lazy loading for better performance" -ForegroundColor Green
    Write-Host "  * Include proper width/height to prevent layout shift" -ForegroundColor Green
    
}
finally {
    Pop-Location
}
