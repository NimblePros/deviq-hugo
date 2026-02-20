# BlueSky Interactions Browser Testing Script
# Helps track and document cross-browser testing results

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Chrome', 'Firefox', 'Safari', 'Edge', 'ChromeMobile', 'SafariMobile', 'FirefoxMobile')]
    [string]$Browser,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowResults,
    
    [Parameter(Mandatory=$false)]
    [switch]$InitializeTests
)

$TestResultsFile = "docs/bluesky-interactions-test-results.json"

# Initialize test results structure
function Initialize-TestResults {
    $testStructure = @{
        testDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        browsers = @{
            Chrome = @{ tested = $false; passed = $false; issues = @() }
            Firefox = @{ tested = $false; passed = $false; issues = @() }
            Safari = @{ tested = $false; passed = $false; issues = @() }
            Edge = @{ tested = $false; passed = $false; issues = @() }
            ChromeMobile = @{ tested = $false; passed = $false; issues = @() }
            SafariMobile = @{ tested = $false; passed = $false; issues = @() }
            FirefoxMobile = @{ tested = $false; passed = $false; issues = @() }
        }
        scenarios = @{
            manyInteractions = @{ tested = $false; passed = $false; browsers = @{} }
            fewInteractions = @{ tested = $false; passed = $false; browsers = @{} }
            zeroInteractions = @{ tested = $false; passed = $false; browsers = @{} }
            invalidUrl = @{ tested = $false; passed = $false; browsers = @{} }
            deletedPost = @{ tested = $false; passed = $false; browsers = @{} }
            apiTimeout = @{ tested = $false; passed = $false; browsers = @{} }
            noJavaScript = @{ tested = $false; passed = $false; browsers = @{} }
            caching = @{ tested = $false; passed = $false; browsers = @{} }
        }
        accessibility = @{
            screenReader = @{ tested = $false; passed = $false; notes = "" }
            keyboardNav = @{ tested = $false; passed = $false; notes = "" }
            colorContrast = @{ tested = $false; passed = $false; notes = "" }
            ariaLabels = @{ tested = $false; passed = $false; notes = "" }
        }
        performance = @{
            bundleSize = @{ value = 0; unit = "KB"; target = 10; passed = $false }
            apiResponseTime = @{ value = 0; unit = "ms"; target = 1000; passed = $false }
            cls = @{ value = 0; target = 0.1; passed = $false }
        }
    }
    
    $testStructure | ConvertTo-Json -Depth 10 | Out-File $TestResultsFile -Encoding UTF8
    Write-Host "✓ Test results file initialized at $TestResultsFile" -ForegroundColor Green
}

# Load test results
function Get-TestResults {
    if (-not (Test-Path $TestResultsFile)) {
        Write-Host "Test results file not found. Run with -InitializeTests first." -ForegroundColor Yellow
        return $null
    }
    
    return Get-Content $TestResultsFile -Raw | ConvertFrom-Json
}

# Save test results
function Save-TestResults {
    param($results)
    $results | ConvertTo-Json -Depth 10 | Out-File $TestResultsFile -Encoding UTF8
}

# Display test results summary
function Show-TestSummary {
    $results = Get-TestResults
    if (-not $results) { return }
    
    Write-Host "`n=== BlueSky Interactions Test Results ===" -ForegroundColor Cyan
    Write-Host "Test Date: $($results.testDate)`n" -ForegroundColor Gray
    
    # Browser Testing Summary
    Write-Host "Browser Testing:" -ForegroundColor Yellow
    foreach ($browser in $results.browsers.PSObject.Properties) {
        $status = if ($browser.Value.tested) {
            if ($browser.Value.passed) { "✓ PASS" } else { "✗ FAIL" }
        } else { "○ Not Tested" }
        
        $color = if ($browser.Value.passed) { "Green" } elseif ($browser.Value.tested) { "Red" } else { "Gray" }
        Write-Host "  $($browser.Name): $status" -ForegroundColor $color
        
        if ($browser.Value.issues.Count -gt 0) {
            foreach ($issue in $browser.Value.issues) {
                Write-Host "    - $issue" -ForegroundColor Red
            }
        }
    }
    
    # Scenario Testing Summary
    Write-Host "`nScenario Testing:" -ForegroundColor Yellow
    foreach ($scenario in $results.scenarios.PSObject.Properties) {
        $status = if ($scenario.Value.tested) {
            if ($scenario.Value.passed) { "✓ PASS" } else { "✗ FAIL" }
        } else { "○ Not Tested" }
        
        $color = if ($scenario.Value.passed) { "Green" } elseif ($scenario.Value.tested) { "Red" } else { "Gray" }
        $scenarioName = $scenario.Name -creplace '([A-Z])', ' $1'
        Write-Host "  $scenarioName : $status" -ForegroundColor $color
    }
    
    # Accessibility Summary
    Write-Host "`nAccessibility Testing:" -ForegroundColor Yellow
    foreach ($test in $results.accessibility.PSObject.Properties) {
        $status = if ($test.Value.tested) {
            if ($test.Value.passed) { "✓ PASS" } else { "✗ FAIL" }
        } else { "○ Not Tested" }
        
        $color = if ($test.Value.passed) { "Green" } elseif ($test.Value.tested) { "Red" } else { "Gray" }
        $testName = $test.Name -creplace '([A-Z])', ' $1'
        Write-Host "  $testName : $status" -ForegroundColor $color
    }
    
    # Performance Summary
    Write-Host "`nPerformance Testing:" -ForegroundColor Yellow
    
    $bundleSize = $results.performance.bundleSize
    $bundleStatus = if ($bundleSize.value -gt 0) {
        if ($bundleSize.value -le $bundleSize.target) { "✓ PASS" } else { "✗ FAIL" }
    } else { "○ Not Tested" }
    Write-Host "  Bundle Size: $bundleStatus ($($bundleSize.value) $($bundleSize.unit) / Target: $($bundleSize.target) $($bundleSize.unit))" -ForegroundColor $(if ($bundleSize.passed) { "Green" } else { "Gray" })
    
    $apiTime = $results.performance.apiResponseTime
    $apiStatus = if ($apiTime.value -gt 0) {
        if ($apiTime.value -le $apiTime.target) { "✓ PASS" } else { "✗ FAIL" }
    } else { "○ Not Tested" }
    Write-Host "  API Response Time: $apiStatus ($($apiTime.value) $($apiTime.unit) / Target: $($apiTime.target) $($apiTime.unit))" -ForegroundColor $(if ($apiTime.passed) { "Green" } else { "Gray" })
    
    $cls = $results.performance.cls
    $clsStatus = if ($cls.value -gt 0) {
        if ($cls.value -le $cls.target) { "✓ PASS" } else { "✗ FAIL" }
    } else { "○ Not Tested" }
    Write-Host "  CLS: $clsStatus ($($cls.value) / Target: $($cls.target))" -ForegroundColor $(if ($cls.passed) { "Green" } else { "Gray" })
    
    # Overall Status
    $totalBrowsers = ($results.browsers.PSObject.Properties | Where-Object { $_.Value.tested }).Count
    $passedBrowsers = ($results.browsers.PSObject.Properties | Where-Object { $_.Value.passed }).Count
    $totalScenarios = ($results.scenarios.PSObject.Properties | Where-Object { $_.Value.tested }).Count
    $passedScenarios = ($results.scenarios.PSObject.Properties | Where-Object { $_.Value.passed }).Count
    
    Write-Host "`n=== Overall Progress ===" -ForegroundColor Cyan
    Write-Host "Browsers: $passedBrowsers/$totalBrowsers passed" -ForegroundColor $(if ($passedBrowsers -eq $totalBrowsers -and $totalBrowsers -gt 0) { "Green" } else { "Yellow" })
    Write-Host "Scenarios: $passedScenarios/$totalScenarios passed" -ForegroundColor $(if ($passedScenarios -eq $totalScenarios -and $totalScenarios -gt 0) { "Green" } else { "Yellow" })
    
    Write-Host ""
}

# Interactive browser testing workflow
function Start-BrowserTest {
    param([string]$Browser)
    
    $results = Get-TestResults
    if (-not $results) { return }
    
    Write-Host "`n=== Testing $Browser ===" -ForegroundColor Cyan
    Write-Host "Make sure Hugo dev server is running (.\build.ps1)`n" -ForegroundColor Yellow
    
    # Test scenarios checklist
    $scenarios = @(
        @{ name = "manyInteractions"; display = "Post with many interactions (50+ likes)" }
        @{ name = "fewInteractions"; display = "Post with few interactions (1-5 likes)" }
        @{ name = "zeroInteractions"; display = "Post with zero interactions" }
        @{ name = "invalidUrl"; display = "Invalid BlueSky URL" }
        @{ name = "deletedPost"; display = "Deleted BlueSky post" }
        @{ name = "apiTimeout"; display = "API timeout/network error (offline mode)" }
        @{ name = "noJavaScript"; display = "JavaScript disabled" }
        @{ name = "caching"; display = "SessionStorage caching" }
    )
    
    Write-Host "Test each scenario in $Browser and press Enter after each:" -ForegroundColor Yellow
    Write-Host "URL: http://localhost:1313/test-bluesky-interactions/`n" -ForegroundColor Gray
    
    foreach ($scenario in $scenarios) {
        Write-Host "Testing: $($scenario.display)" -ForegroundColor Cyan
        $response = Read-Host "Did this scenario pass? (y/n/s to skip)"
        
        if ($response -eq 's') {
            continue
        }
        
        $passed = $response -eq 'y'
        $results.scenarios.($scenario.name).tested = $true
        $results.scenarios.($scenario.name).passed = $passed
        
        if (-not $results.scenarios.($scenario.name).browsers) {
            $results.scenarios.($scenario.name).browsers = @{}
        }
        $results.scenarios.($scenario.name).browsers.$Browser = $passed
        
        if (-not $passed) {
            $issue = Read-Host "Describe the issue"
            if (-not $results.browsers.$Browser.issues) {
                $results.browsers.$Browser.issues = @()
            }
            $results.browsers.$Browser.issues += "$($scenario.display): $issue"
        }
    }
    
    # Update browser status
    $results.browsers.$Browser.tested = $true
    $allPassed = ($results.scenarios.PSObject.Properties | Where-Object { 
        $_.Value.browsers.$Browser -ne $null 
    } | ForEach-Object { $_.Value.browsers.$Browser }).Count -gt 0 -and
    ($results.scenarios.PSObject.Properties | Where-Object { 
        $_.Value.browsers.$Browser -eq $false 
    }).Count -eq 0
    
    $results.browsers.$Browser.passed = $allPassed
    
    Save-TestResults $results
    
    Write-Host "`n✓ $Browser testing complete!" -ForegroundColor Green
    Write-Host "Results saved to $TestResultsFile" -ForegroundColor Gray
}

# Main script logic
if ($InitializeTests) {
    Initialize-TestResults
}
elseif ($ShowResults) {
    Show-TestSummary
}
elseif ($Browser) {
    Start-BrowserTest -Browser $Browser
}
else {
    Write-Host "BlueSky Interactions Browser Testing Script" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\scripts\test-bluesky-browser.ps1 -InitializeTests    # Create test results file"
    Write-Host "  .\scripts\test-bluesky-browser.ps1 -Browser Chrome     # Test in Chrome"
    Write-Host "  .\scripts\test-bluesky-browser.ps1 -ShowResults        # Show test summary"
    Write-Host ""
    Write-Host "Available browsers:" -ForegroundColor Yellow
    Write-Host "  Chrome, Firefox, Safari, Edge, ChromeMobile, SafariMobile, FirefoxMobile"
    Write-Host ""
}
