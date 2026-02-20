# Build script for NimblePros Hugo blog
# Builds the site, runs pagefind indexing, and optionally starts the dev server

param(
    [switch]$Production
)

# Optimize images (skip in production builds)
if (-not $Production) {
    Write-Host "Optimizing images..." -ForegroundColor Cyan
    & "$PSScriptRoot\optimize-images.ps1"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Image optimization failed!" -ForegroundColor Red
        exit 1
    }
}

# Install npm dependencies
Write-Host "Installing npm dependencies..." -ForegroundColor Cyan
npm install

if ($LASTEXITCODE -ne 0) {
    Write-Host "npm install failed!" -ForegroundColor Red
    exit 1
}

# Build CSS with PostCSS/Tailwind
Write-Host "`nBuilding CSS..." -ForegroundColor Cyan
npm run build:css

if ($LASTEXITCODE -ne 0) {
    Write-Host "CSS build failed!" -ForegroundColor Red
    exit 1
}

# Minify CSS for production
if ($Production) {
    Write-Host "`nMinifying CSS for production..." -ForegroundColor Cyan
    npx postcss static/css/style.css --use cssnano --no-map -o static/css/style.css

    if ($LASTEXITCODE -ne 0) {
        Write-Host "CSS minification failed!" -ForegroundColor Red
        exit 1
    }
}

# Build Hugo site
Write-Host "`nBuilding Hugo site..." -ForegroundColor Cyan
if ($Production) {
    $env:HUGO_ENVIRONMENT = "production"
    hugo --minify --cleanDestinationDir
} else {
    hugo --cleanDestinationDir
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Hugo build failed!" -ForegroundColor Red
    exit 1
}

# Build Pagefind search index
Write-Host "`nBuilding Pagefind search index..." -ForegroundColor Cyan
npx pagefind --site public

if ($LASTEXITCODE -ne 0) {
    Write-Host "Pagefind build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`nBuild complete!" -ForegroundColor Green

if (-not $Production) {
    Write-Host "`nStarting Hugo dev server..." -ForegroundColor Cyan
    hugo server --disableFastRender
}
