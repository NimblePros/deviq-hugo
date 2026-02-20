# Visual Regression Testing - Compare Changes
# Compares current CSS against baseline reference screenshots

param(
    [string]$Filter = "",
    [switch]$Approve = $false
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Visual Regression Testing - Compare Changes" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Check if BackstopJS is installed
if (-not (Test-Path "node_modules/backstopjs")) {
    Write-Host "✗ BackstopJS not found. Run .\scripts\test-setup.ps1 first" -ForegroundColor Red
    exit 1
}

# Check if baseline exists
if (-not (Test-Path "backstop_data/bitmaps_reference")) {
    Write-Host "✗ No baseline reference found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please capture baseline first:" -ForegroundColor Yellow
    Write-Host "  .\scripts\test-baseline.ps1" -ForegroundColor Cyan
    exit 1
}

# Check if Hugo server is running
Write-Host "Checking if Hugo server is running..." -ForegroundColor Yellow
try {
    $null = Invoke-WebRequest -Uri "http://localhost:1313" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
    Write-Host "✓ Hugo server is running" -ForegroundColor Green
} catch {
    Write-Host "✗ Hugo server not detected at http://localhost:1313" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start the Hugo server first:" -ForegroundColor Yellow
    Write-Host "  hugo server" -ForegroundColor Cyan
    exit 1
}

Write-Host ""
if ($Filter) {
    Write-Host "Running tests (filtered: $Filter)..." -ForegroundColor Cyan
    npx backstopjs test --filter=$Filter
} else {
    Write-Host "Running all visual regression tests..." -ForegroundColor Cyan
    Write-Host "This may take a few moments..." -ForegroundColor Gray
    Write-Host ""
    npx backstopjs test
}

$testExitCode = $LASTEXITCODE

if ($testExitCode -eq 0) {
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host "✓ All visual regression tests passed!" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host ""
    Write-Host "No visual differences detected." -ForegroundColor White
    exit 0
} else {
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host "⚠ Visual differences detected" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "A detailed report has been opened in your browser." -ForegroundColor White
    Write-Host ""
    Write-Host "Review the differences:" -ForegroundColor Yellow
    Write-Host "  - RED areas = pixels removed" -ForegroundColor Red
    Write-Host "  - GREEN areas = pixels added" -ForegroundColor Green
    Write-Host "  - Side-by-side comparison available" -ForegroundColor White
    Write-Host ""
    
    if ($Approve) {
        Write-Host "Approving changes and updating baseline..." -ForegroundColor Cyan
        npx backstopjs approve
        Write-Host "✓ Baseline updated with new screenshots" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "If these changes are intentional, approve them:" -ForegroundColor Yellow
        Write-Host "  .\scripts\test-visual-regression.ps1 -Approve" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Or to test a specific scenario:" -ForegroundColor Yellow
        Write-Host "  .\scripts\test-visual-regression.ps1 -Filter 'Homepage'" -ForegroundColor Cyan
        exit 1
    }
}
