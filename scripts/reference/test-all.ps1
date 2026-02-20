# Run All CSS Tests
# Comprehensive test suite for CSS refactoring validation

param(
    [switch]$SkipVisual = $false,
    [switch]$SkipAccessibility = $false,
    [switch]$SkipPerformance = $false,
    [switch]$SkipValidation = $false
)

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "CSS Refactoring - Complete Test Suite" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date
$allTestsPassed = $true
$testResults = @()

# Check if Hugo server is running
Write-Host "Pre-flight checks..." -ForegroundColor Yellow
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

# 1. CSS Validation
if (-not $SkipValidation) {
    Write-Host ""
    Write-Host "┌" + ("─" * 78) + "┐" -ForegroundColor Cyan
    Write-Host "│" + (" " * 27) + "CSS VALIDATION" + (" " * 37) + "│" -ForegroundColor Cyan
    Write-Host "└" + ("─" * 78) + "┘" -ForegroundColor Cyan
    Write-Host ""
    
    & "$PSScriptRoot\test-css-validation.ps1"
    $validationResult = $LASTEXITCODE -eq 0
    $testResults += [PSCustomObject]@{
        Test = "CSS Validation"
        Passed = $validationResult
        Status = if ($validationResult) { "✓ Pass" } else { "✗ Fail" }
    }
    if (-not $validationResult) { $allTestsPassed = $false }
} else {
    Write-Host "⊘ Skipping CSS validation" -ForegroundColor Gray
}

# 2. Visual Regression Testing
if (-not $SkipVisual) {
    Write-Host ""
    Write-Host "┌" + ("─" * 78) + "┐" -ForegroundColor Cyan
    Write-Host "│" + (" " * 23) + "VISUAL REGRESSION TESTING" + (" " * 30) + "│" -ForegroundColor Cyan
    Write-Host "└" + ("─" * 78) + "┘" -ForegroundColor Cyan
    Write-Host ""
    
    if (Test-Path "backstop_data/bitmaps_reference") {
        & "$PSScriptRoot\test-visual-regression.ps1"
        $visualResult = $LASTEXITCODE -eq 0
        $testResults += [PSCustomObject]@{
            Test = "Visual Regression"
            Passed = $visualResult
            Status = if ($visualResult) { "✓ Pass" } else { "✗ Fail" }
        }
        if (-not $visualResult) { $allTestsPassed = $false }
    } else {
        Write-Host "⚠ No baseline reference found. Skipping visual regression." -ForegroundColor Yellow
        Write-Host "  Run: .\scripts\test-baseline.ps1" -ForegroundColor Gray
        $testResults += [PSCustomObject]@{
            Test = "Visual Regression"
            Passed = $null
            Status = "⊘ Skipped"
        }
    }
} else {
    Write-Host "⊘ Skipping visual regression testing" -ForegroundColor Gray
}

# 3. Accessibility Testing
if (-not $SkipAccessibility) {
    Write-Host ""
    Write-Host "┌" + ("─" * 78) + "┐" -ForegroundColor Cyan
    Write-Host "│" + (" " * 25) + "ACCESSIBILITY TESTING" + (" " * 32) + "│" -ForegroundColor Cyan
    Write-Host "└" + ("─" * 78) + "┘" -ForegroundColor Cyan
    Write-Host ""
    
    & "$PSScriptRoot\test-accessibility.ps1"
    $a11yResult = $LASTEXITCODE -eq 0
    $testResults += [PSCustomObject]@{
        Test = "Accessibility"
        Passed = $a11yResult
        Status = if ($a11yResult) { "✓ Pass" } else { "✗ Fail" }
    }
    if (-not $a11yResult) { $allTestsPassed = $false }
} else {
    Write-Host "⊘ Skipping accessibility testing" -ForegroundColor Gray
}

# 4. Performance Testing
if (-not $SkipPerformance) {
    Write-Host ""
    Write-Host "┌" + ("─" * 78) + "┐" -ForegroundColor Cyan
    Write-Host "│" + (" " * 26) + "PERFORMANCE TESTING" + (" " * 33) + "│" -ForegroundColor Cyan
    Write-Host "└" + ("─" * 78) + "┘" -ForegroundColor Cyan
    Write-Host ""
    
    & "$PSScriptRoot\test-performance.ps1" -After
    $perfResult = $LASTEXITCODE -eq 0
    $testResults += [PSCustomObject]@{
        Test = "Performance"
        Passed = $perfResult
        Status = if ($perfResult) { "✓ Pass" } else { "✗ Fail" }
    }
    if (-not $perfResult) { $allTestsPassed = $false }
} else {
    Write-Host "⊘ Skipping performance testing" -ForegroundColor Gray
}

# Summary
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Test Suite Summary" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

$testResults | Format-Table -AutoSize Test, Status

Write-Host ""
Write-Host "Duration: $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Gray
Write-Host ""

if ($allTestsPassed) {
    Write-Host "┌" + ("─" * 78) + "┐" -ForegroundColor Green
    Write-Host "│" + (" " * 26) + "ALL TESTS PASSED! ✓" + (" " * 32) + "│" -ForegroundColor Green
    Write-Host "└" + ("─" * 78) + "┘" -ForegroundColor Green
    Write-Host ""
    Write-Host "✓ CSS refactoring is ready for deployment" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Review TESTING-CHECKLIST.md for manual tests" -ForegroundColor White
    Write-Host "  2. Test on real devices (not just DevTools)" -ForegroundColor White
    Write-Host "  3. Deploy to staging for final validation" -ForegroundColor White
    Write-Host "  4. Monitor for 24-48 hours before production" -ForegroundColor White
    Write-Host ""
    exit 0
} else {
    Write-Host "┌" + ("─" * 78) + "┐" -ForegroundColor Red
    Write-Host "│" + (" " * 29) + "TESTS FAILED ✗" + (" " * 34) + "│" -ForegroundColor Red
    Write-Host "└" + ("─" * 78) + "┘" -ForegroundColor Red
    Write-Host ""
    Write-Host "✗ Some tests failed. Please review and fix issues." -ForegroundColor Red
    Write-Host ""
    Write-Host "To skip specific test categories:" -ForegroundColor Yellow
    Write-Host "  .\scripts\test-all.ps1 -SkipVisual" -ForegroundColor Cyan
    Write-Host "  .\scripts\test-all.ps1 -SkipAccessibility" -ForegroundColor Cyan
    Write-Host "  .\scripts\test-all.ps1 -SkipPerformance" -ForegroundColor Cyan
    Write-Host "  .\scripts\test-all.ps1 -SkipValidation" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}
