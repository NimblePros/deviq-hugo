# Accessibility Testing Script
# Tests pages for accessibility issues using pa11y

param(
    [string[]]$Urls = @(
        "http://localhost:1313/",
        "http://localhost:1313/blog/",
        "http://localhost:1313/about/",
        "http://localhost:1313/books/"
    ),
    [ValidateSet("WCAG2A", "WCAG2AA", "WCAG2AAA")]
    [string]$Standard = "WCAG2AA",
    [switch]$Detailed = $false
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Accessibility Testing" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Check if pa11y is installed
if (-not (Test-Path "node_modules/pa11y")) {
    Write-Host "✗ pa11y not found. Run .\scripts\test-setup.ps1 first" -ForegroundColor Red
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
Write-Host "Testing standard: $Standard" -ForegroundColor White
Write-Host "Testing $($Urls.Count) URL(s)..." -ForegroundColor White
Write-Host ""

$allPassed = $true
$totalIssues = 0
$results = @()

foreach ($url in $Urls) {
    Write-Host ("─" * 80) -ForegroundColor Gray
    Write-Host "Testing: $url" -ForegroundColor Cyan
    
    # Create output file path
    $urlHash = $url -replace '[^a-zA-Z0-9]', '-'
    $outputFile = "test-results/accessibility/pa11y-$urlHash.json"
    
    # Run pa11y
    $pa11yArgs = @(
        $url,
        "--standard", $Standard,
        "--reporter", "json"
    )
    
    $jsonOutput = npx pa11y @pa11yArgs 2>&1 | Out-String
    
    try {
        $result = $jsonOutput | ConvertFrom-Json
        $issueCount = $result.issues.Count
        
        # Save results
        $jsonOutput | Out-File -FilePath $outputFile -Encoding UTF8
        
        if ($issueCount -eq 0) {
            Write-Host "  ✓ No accessibility issues found" -ForegroundColor Green
        } else {
            $allPassed = $false
            $totalIssues += $issueCount
            Write-Host "  ✗ Found $issueCount accessibility issue(s)" -ForegroundColor Red
            
            if ($Detailed) {
                Write-Host ""
                foreach ($issue in $result.issues) {
                    Write-Host "    Issue: $($issue.message)" -ForegroundColor Yellow
                    Write-Host "    Type: $($issue.type)" -ForegroundColor Gray
                    Write-Host "    Code: $($issue.code)" -ForegroundColor Gray
                    Write-Host "    Selector: $($issue.selector)" -ForegroundColor Gray
                    Write-Host ""
                }
            }
        }
        
        $results += [PSCustomObject]@{
            Url = $url
            Issues = $issueCount
            Passed = ($issueCount -eq 0)
        }
        
    } catch {
        Write-Host "  ✗ Error parsing results" -ForegroundColor Red
        $allPassed = $false
    }
    
    Write-Host ""
}

# Summary
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Accessibility Test Summary" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

$results | Format-Table -AutoSize Url, Issues, @{
    Name = 'Status'
    Expression = { if ($_.Passed) { '✓ Pass' } else { '✗ Fail' } }
}

Write-Host ""
Write-Host "Total issues found: $totalIssues" -ForegroundColor $(if ($totalIssues -eq 0) { 'Green' } else { 'Yellow' })
Write-Host "Results saved to: test-results/accessibility/" -ForegroundColor Gray
Write-Host ""

if (-not $Detailed -and $totalIssues -gt 0) {
    Write-Host "For detailed issue information, run with -Detailed flag:" -ForegroundColor Yellow
    Write-Host "  .\scripts\test-accessibility.ps1 -Detailed" -ForegroundColor Cyan
    Write-Host ""
}

if ($allPassed) {
    Write-Host "✓ All accessibility tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ Accessibility issues found" -ForegroundColor Red
    Write-Host ""
    Write-Host "Review and fix accessibility issues before deployment." -ForegroundColor Yellow
    exit 1
}
