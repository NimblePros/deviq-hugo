# BlueSky Interactions Performance Testing Script
# Measures and validates performance metrics

param(
    [Parameter(Mandatory=$false)]
    [switch]$MeasureBundleSize,
    
    [Parameter(Mandatory=$false)]
    [switch]$MeasureApiResponse,
    
    [Parameter(Mandatory=$false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory=$false)]
    [string]$TestUrl = "http://localhost:1313/test-bluesky-interactions/"
)

$ResultsFile = "docs/bluesky-performance-results.json"

# Measure JavaScript bundle size
function Measure-BundleSize {
    Write-Host "`n=== JavaScript Bundle Size ===" -ForegroundColor Cyan
    
    $jsFile = "static/js/bluesky-interactions.js"
    
    if (-not (Test-Path $jsFile)) {
        Write-Host "Error: File not found: $jsFile" -ForegroundColor Red
        return $null
    }
    
    $fileInfo = Get-Item $jsFile
    $sizeKB = [math]::Round($fileInfo.Length / 1KB, 2)
    $targetKB = 10
    $passed = $sizeKB -le $targetKB
    
    $color = if ($passed) { "Green" } else { "Red" }
    $status = if ($passed) { "✓ PASS" } else { "✗ FAIL" }
    
    Write-Host "File: $jsFile" -ForegroundColor Gray
    Write-Host "Size: $sizeKB KB" -ForegroundColor $color
    Write-Host "Target: ≤ $targetKB KB" -ForegroundColor Gray
    Write-Host "Status: $status" -ForegroundColor $color
    
    # Check if minified version would be smaller
    $lines = (Get-Content $jsFile | Measure-Object -Line).Lines
    $characters = (Get-Content $jsFile -Raw).Length
    $avgLineLength = [math]::Round($characters / $lines, 0)
    
    Write-Host "`nFile Statistics:" -ForegroundColor Yellow
    Write-Host "  Lines: $lines" -ForegroundColor Gray
    Write-Host "  Characters: $characters" -ForegroundColor Gray
    Write-Host "  Avg Line Length: $avgLineLength" -ForegroundColor Gray
    
    # Estimate gzip size (rough approximation: 25-30% of original)
    $estimatedGzipKB = [math]::Round($sizeKB * 0.28, 2)
    Write-Host "  Estimated Gzip: ~$estimatedGzipKB KB" -ForegroundColor Gray
    
    return @{
        sizeKB = $sizeKB
        targetKB = $targetKB
        passed = $passed
        lines = $lines
        estimatedGzipKB = $estimatedGzipKB
    }
}

# Instructions for measuring API response time
function Show-ApiResponseInstructions {
    Write-Host "`n=== API Response Time Testing ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To measure BlueSky API response time:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Open browser to: $TestUrl" -ForegroundColor Gray
    Write-Host "2. Open Developer Tools (F12)" -ForegroundColor Gray
    Write-Host "3. Go to Network tab" -ForegroundColor Gray
    Write-Host "4. Filter by 'Fetch/XHR'" -ForegroundColor Gray
    Write-Host "5. Refresh the page" -ForegroundColor Gray
    Write-Host "6. Find request to 'app.bsky.feed.getPostThread'" -ForegroundColor Gray
    Write-Host "7. Note the 'Time' column value" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Target: < 1000ms (1 second)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Repeat 3-5 times and calculate average" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Example measurements:" -ForegroundColor Yellow
    Write-Host "  Try 1: 347ms" -ForegroundColor Gray
    Write-Host "  Try 2: 412ms" -ForegroundColor Gray
    Write-Host "  Try 3: 389ms" -ForegroundColor Gray
    Write-Host "  Average: 383ms ✓ PASS" -ForegroundColor Green
    Write-Host ""
}

# Instructions for measuring Core Web Vitals
function Show-CoreWebVitalsInstructions {
    Write-Host "`n=== Core Web Vitals Testing ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Method 1: Chrome DevTools Lighthouse" -ForegroundColor Yellow
    Write-Host "1. Open Chrome DevTools (F12)" -ForegroundColor Gray
    Write-Host "2. Go to 'Lighthouse' tab" -ForegroundColor Gray
    Write-Host "3. Select 'Performance' category" -ForegroundColor Gray
    Write-Host "4. Click 'Analyze page load'" -ForegroundColor Gray
    Write-Host "5. Review metrics in report:" -ForegroundColor Gray
    Write-Host "   - Largest Contentful Paint (LCP) - Target: < 2.5s" -ForegroundColor Gray
    Write-Host "   - Cumulative Layout Shift (CLS) - Target: < 0.1" -ForegroundColor Gray
    Write-Host "   - First Input Delay (FID) - Target: < 100ms" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Method 2: Chrome DevTools Performance Tab" -ForegroundColor Yellow
    Write-Host "1. Open Chrome DevTools → Performance" -ForegroundColor Gray
    Write-Host "2. Click record button" -ForegroundColor Gray
    Write-Host "3. Refresh page" -ForegroundColor Gray
    Write-Host "4. Stop recording" -ForegroundColor Gray
    Write-Host "5. Look for 'Experience' section" -ForegroundColor Gray
    Write-Host "6. Check 'Layout Shifts' - should be minimal" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Method 3: web.dev/measure" -ForegroundColor Yellow
    Write-Host "1. Deploy to preview environment" -ForegroundColor Gray
    Write-Host "2. Go to https://web.dev/measure/" -ForegroundColor Gray
    Write-Host "3. Enter URL" -ForegroundColor Gray
    Write-Host "4. Review Core Web Vitals report" -ForegroundColor Gray
    Write-Host ""
}

# Instructions for cache performance testing
function Show-CacheTestingInstructions {
    Write-Host "`n=== SessionStorage Cache Testing ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Test 1: Verify Caching Works" -ForegroundColor Yellow
    Write-Host "1. Open browser to: $TestUrl" -ForegroundColor Gray
    Write-Host "2. Open DevTools → Network tab" -ForegroundColor Gray
    Write-Host "3. Note API request to getPostThread" -ForegroundColor Gray
    Write-Host "4. Refresh page (F5)" -ForegroundColor Gray
    Write-Host "5. Check Network tab - should NOT show new API request" -ForegroundColor Gray
    Write-Host "6. Verify ✓ PASS if no API request on refresh" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Test 2: Verify Cache in sessionStorage" -ForegroundColor Yellow
    Write-Host "1. Open DevTools → Application tab" -ForegroundColor Gray
    Write-Host "2. Expand 'Session Storage'" -ForegroundColor Gray
    Write-Host "3. Click on your site" -ForegroundColor Gray
    Write-Host "4. Look for key starting with 'bluesky_post_'" -ForegroundColor Gray
    Write-Host "5. Verify data is cached with timestamp" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Test 3: Verify Cache Expiration (5 minutes)" -ForegroundColor Yellow
    Write-Host "1. Load page and verify cache is set" -ForegroundColor Gray
    Write-Host "2. Wait 6 minutes (or modify timestamp in sessionStorage)" -ForegroundColor Gray
    Write-Host "3. Refresh page" -ForegroundColor Gray
    Write-Host "4. Verify new API request is made" -ForegroundColor Gray
    Write-Host "5. Verify ✓ PASS if new request after expiration" -ForegroundColor Gray
    Write-Host ""
}

# Instructions for network throttling tests
function Show-NetworkThrottlingInstructions {
    Write-Host "`n=== Network Throttling Testing ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Test on Slow Networks" -ForegroundColor Yellow
    Write-Host "1. Open Chrome DevTools → Network tab" -ForegroundColor Gray
    Write-Host "2. Click throttling dropdown (next to 'Disable cache')" -ForegroundColor Gray
    Write-Host "3. Select 'Fast 3G'" -ForegroundColor Gray
    Write-Host "4. Refresh page" -ForegroundColor Gray
    Write-Host "5. Verify:" -ForegroundColor Gray
    Write-Host "   - Loading spinner appears" -ForegroundColor Gray
    Write-Host "   - Content loads eventually" -ForegroundColor Gray
    Write-Host "   - No timeout errors" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Repeat with 'Slow 3G' throttling" -ForegroundColor Yellow
    Write-Host ""
}

# Generate performance report
function New-PerformanceReport {
    Write-Host "`n=== Performance Testing Report ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Bundle size
    $bundleSize = Measure-BundleSize
    
    # Show other test instructions
    Show-ApiResponseInstructions
    Show-CoreWebVitalsInstructions
    Show-CacheTestingInstructions
    Show-NetworkThrottlingInstructions
    
    # Save bundle size results
    $results = @{
        testDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        bundleSize = $bundleSize
        testUrl = $TestUrl
    }
    
    $results | ConvertTo-Json -Depth 10 | Out-File $ResultsFile -Encoding UTF8
    
    Write-Host "`n=== Summary ===" -ForegroundColor Cyan
    Write-Host "Bundle Size Test: $(if ($bundleSize.passed) { '✓ PASS' } else { '✗ FAIL' })" -ForegroundColor $(if ($bundleSize.passed) { "Green" } else { "Red" })
    Write-Host ""
    Write-Host "Complete manual tests above and document results in:" -ForegroundColor Yellow
    Write-Host "  docs/bluesky-interactions-testing.md" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Automated results saved to: $ResultsFile" -ForegroundColor Gray
    Write-Host ""
}

# Main script
if ($MeasureBundleSize) {
    Measure-BundleSize | Out-Null
}
elseif ($MeasureApiResponse) {
    Show-ApiResponseInstructions
}
elseif ($GenerateReport) {
    New-PerformanceReport
}
else {
    Write-Host "BlueSky Interactions Performance Testing" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\scripts\test-bluesky-performance.ps1 -MeasureBundleSize    # Check JS file size"
    Write-Host "  .\scripts\test-bluesky-performance.ps1 -MeasureApiResponse   # API timing instructions"
    Write-Host "  .\scripts\test-bluesky-performance.ps1 -GenerateReport       # Full performance report"
    Write-Host ""
    Write-Host "Performance Targets:" -ForegroundColor Yellow
    Write-Host "  JavaScript Bundle: < 10 KB" -ForegroundColor Gray
    Write-Host "  API Response Time: < 1000ms" -ForegroundColor Gray
    Write-Host "  CLS (Cumulative Layout Shift): < 0.1" -ForegroundColor Gray
    Write-Host "  sessionStorage caching: Working" -ForegroundColor Gray
    Write-Host ""
}
