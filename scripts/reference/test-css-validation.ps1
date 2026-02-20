# CSS Validation Script
# Validates CSS syntax and best practices using stylelint

param(
    [string]$File = "static/css/*.css",
    [switch]$Fix = $false
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "CSS Validation" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Check if Node.js is installed
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "✗ Node.js not found. Please install Node.js" -ForegroundColor Red
    exit 1
}

# Check if stylelint is installed
if (-not (Test-Path "node_modules/stylelint")) {
    Write-Host "✗ stylelint not found. Run .\scripts\test-setup.ps1 first" -ForegroundColor Red
    exit 1
}

Write-Host "Validating: $File" -ForegroundColor Yellow
Write-Host ""

if ($Fix) {
    Write-Host "Running with auto-fix enabled..." -ForegroundColor Cyan
    npx stylelint $File --fix
} else {
    npx stylelint $File
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Green
    Write-Host "✓ CSS validation passed!" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor Red
    Write-Host "✗ CSS validation failed" -ForegroundColor Red
    Write-Host "=" * 80 -ForegroundColor Red
    Write-Host ""
    Write-Host "Tip: Run with -Fix flag to auto-fix some issues:" -ForegroundColor Yellow
    Write-Host "  .\scripts\test-css-validation.ps1 -Fix" -ForegroundColor Cyan
    exit 1
}
