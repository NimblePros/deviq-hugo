# Visual Regression Testing - Baseline Capture
# Captures reference screenshots before making CSS changes

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Visual Regression Testing - Baseline Capture" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Check if BackstopJS is installed
if (-not (Test-Path "node_modules/backstopjs")) {
    Write-Host "✗ BackstopJS not found. Run .\scripts\test-setup.ps1 first" -ForegroundColor Red
    exit 1
}

# Check if Hugo server is running
Write-Host "Checking if Hugo server is running..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:1313" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
    Write-Host "✓ Hugo server is running at http://localhost:1313" -ForegroundColor Green
} catch {
    Write-Host "✗ Hugo server not detected at http://localhost:1313" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start the Hugo server first:" -ForegroundColor Yellow
    Write-Host "  hugo server" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or if it's running on a different port, update backstop.json" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Capturing reference screenshots..." -ForegroundColor Cyan
Write-Host "This will take a few moments..." -ForegroundColor Gray
Write-Host ""

npx backstopjs reference

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host "✓ Baseline screenshots captured successfully!" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host ""
    Write-Host "Screenshots saved to: backstop_data/bitmaps_reference/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Make your CSS changes in style-v2.css" -ForegroundColor White
    Write-Host "  2. Run comparison test: " -ForegroundColor White -NoNewline
    Write-Host ".\scripts\test-visual-regression.ps1" -ForegroundColor Cyan
    Write-Host ""
    exit 0
} else {
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Red
    Write-Host "✗ Baseline capture failed" -ForegroundColor Red
    Write-Host "=" * 80 -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  - Make sure Hugo server is running" -ForegroundColor White
    Write-Host "  - Check that URLs in backstop.json are correct" -ForegroundColor White
    Write-Host "  - Ensure all test pages exist" -ForegroundColor White
    exit 1
}
