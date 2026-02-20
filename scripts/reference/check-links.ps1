# Check Links Script for ardalis.com
# Runs Hugo build then lychee link checker against the output
#
# Usage:
#   .\scripts\check-links.ps1              # Build + check internal links
#   .\scripts\check-links.ps1 -SkipBuild   # Check only (assumes public/ exists)
#   .\scripts\check-links.ps1 -IncludeExternal  # Also check external links (slow)

param(
    [switch]$SkipBuild,
    [switch]$IncludeExternal,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot\..

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Broken Link Checker for ardalis.com" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build the site
if (-not $SkipBuild) {
    Write-Host "[1/3] Building site with Hugo..." -ForegroundColor Yellow
    $buildStart = Get-Date
    hugo --cleanDestinationDir --quiet
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Hugo build failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
    $buildTime = (Get-Date) - $buildStart
    Write-Host "      Build completed in $([math]::Round($buildTime.TotalSeconds, 1))s" -ForegroundColor Green
} else {
    Write-Host "[1/3] Skipping build (using existing public/ directory)" -ForegroundColor DarkGray
    if (-not (Test-Path "public/index.html")) {
        Write-Host "ERROR: public/index.html not found. Run without -SkipBuild first." -ForegroundColor Red
        exit 1
    }
}

# Step 2: Check that lychee is available
Write-Host "[2/3] Checking for lychee..." -ForegroundColor Yellow
$lychee = Get-Command lychee -ErrorAction SilentlyContinue
if (-not $lychee) {
    Write-Host "ERROR: lychee not found. Install it:" -ForegroundColor Red
    Write-Host "  winget install lycheeverse.lychee" -ForegroundColor White
    Write-Host "  (then restart your terminal)" -ForegroundColor White
    exit 1
}
$lycheeVersion = & lychee --version 2>&1
Write-Host "      Found $lycheeVersion" -ForegroundColor Green

# Step 3: Run lychee
Write-Host "[3/3] Scanning for broken links..." -ForegroundColor Yellow

$lycheeArgs = @()

if ($IncludeExternal) {
    Write-Host "      Mode: internal + external links (this may take a while)" -ForegroundColor DarkYellow
    $lycheeArgs += "--config"
    $lycheeArgs += "lychee-external.toml"
} else {
    Write-Host "      Mode: internal links only (offline)" -ForegroundColor DarkGray
    # Uses .lychee.toml automatically (offline, excludes external URLs)
}

if ($Verbose) {
    $lycheeArgs += "--verbose"
}

$lycheeArgs += "--no-progress"
$lycheeArgs += "public/**/*.html"

$scanStart = Get-Date

# Run lychee. It uses .lychee.toml automatically from the project root.
& lychee @lycheeArgs
$lycheeExit = $LASTEXITCODE

$scanTime = (Get-Date) - $scanStart

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Scan completed in $([math]::Round($scanTime.TotalSeconds, 1))s" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

if ($lycheeExit -eq 0) {
    Write-Host "  Result: ALL LINKS OK" -ForegroundColor Green
} elseif ($lycheeExit -eq 2) {
    Write-Host "  Result: BROKEN LINKS FOUND (see above)" -ForegroundColor Red
    Write-Host "  Tip: Add false positives to .lychee.toml exclude list" -ForegroundColor DarkGray
} else {
    Write-Host "  Result: lychee exited with code $lycheeExit" -ForegroundColor Yellow
}

Write-Host ""
exit $lycheeExit
