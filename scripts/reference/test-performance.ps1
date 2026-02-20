# Performance Testing Script
# Runs Lighthouse audits to measure performance impact of CSS changes

param(
    [string[]]$Urls = @("http://localhost:1313/"),
    [switch]$Before = $false,
    [switch]$After = $false,
    [switch]$Compare = $false
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Performance Testing (Lighthouse)" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Check if lighthouse is installed
if (-not (Test-Path "node_modules/lighthouse")) {
    Write-Host "✗ Lighthouse not found. Run .\scripts\test-setup.ps1 first" -ForegroundColor Red
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

# Determine suffix based on flags
$suffix = "test"
if ($Before) {
    $suffix = "before"
    Write-Host "Running BEFORE refactor baseline..." -ForegroundColor Yellow
} elseif ($After) {
    $suffix = "after"
    Write-Host "Running AFTER refactor comparison..." -ForegroundColor Yellow
} else {
    Write-Host "Running performance audit..." -ForegroundColor Yellow
}

Write-Host "Testing $($Urls.Count) URL(s)..." -ForegroundColor White
Write-Host ""

$results = @()

foreach ($url in $Urls) {
    Write-Host ("─" * 80) -ForegroundColor Gray
    Write-Host "Testing: $url" -ForegroundColor Cyan
    Write-Host "This may take 30-60 seconds..." -ForegroundColor Gray
    Write-Host ""
    
    # Create safe filename
    $urlHash = $url -replace '[^a-zA-Z0-9]', '-'
    $outputJson = "test-results/lighthouse/lighthouse-$urlHash-$suffix.json"
    $outputHtml = "test-results/lighthouse/lighthouse-$urlHash-$suffix.html"
    
    # Run Lighthouse
    npx lighthouse $url `
        --output=json `
        --output=html `
        --output-path="test-results/lighthouse/lighthouse-$urlHash-$suffix" `
        --quiet `
        --chrome-flags="--headless"
    
    if (Test-Path $outputJson) {
        $report = Get-Content $outputJson -Raw | ConvertFrom-Json
        
        $scores = [PSCustomObject]@{
            Url = $url
            Performance = [math]::Round($report.categories.performance.score * 100)
            Accessibility = [math]::Round($report.categories.accessibility.score * 100)
            BestPractices = [math]::Round($report.categories.'best-practices'.score * 100)
            SEO = [math]::Round($report.categories.seo.score * 100)
            FCP = [math]::Round($report.audits.'first-contentful-paint'.numericValue)
            LCP = [math]::Round($report.audits.'largest-contentful-paint'.numericValue)
            CLS = [math]::Round($report.audits.'cumulative-layout-shift'.numericValue, 3)
            TBT = [math]::Round($report.audits.'total-blocking-time'.numericValue)
        }
        
        $results += $scores
        
        Write-Host "  Performance:    $($scores.Performance)/100" -ForegroundColor $(if ($scores.Performance -ge 90) { 'Green' } elseif ($scores.Performance -ge 50) { 'Yellow' } else { 'Red' })
        Write-Host "  Accessibility:  $($scores.Accessibility)/100" -ForegroundColor $(if ($scores.Accessibility -ge 90) { 'Green' } elseif ($scores.Accessibility -ge 50) { 'Yellow' } else { 'Red' })
        Write-Host "  Best Practices: $($scores.BestPractices)/100" -ForegroundColor $(if ($scores.BestPractices -ge 90) { 'Green' } elseif ($scores.BestPractices -ge 50) { 'Yellow' } else { 'Red' })
        Write-Host "  SEO:            $($scores.SEO)/100" -ForegroundColor $(if ($scores.SEO -ge 90) { 'Green' } elseif ($scores.SEO -ge 50) { 'Yellow' } else { 'Red' })
        Write-Host ""
        Write-Host "  Core Web Vitals:" -ForegroundColor White
        Write-Host "    FCP: $($scores.FCP)ms" -ForegroundColor Gray
        Write-Host "    LCP: $($scores.LCP)ms" -ForegroundColor Gray
        Write-Host "    CLS: $($scores.CLS)" -ForegroundColor Gray
        Write-Host "    TBT: $($scores.TBT)ms" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Reports saved:" -ForegroundColor White
        Write-Host "    JSON: $outputJson" -ForegroundColor Gray
        Write-Host "    HTML: $outputHtml" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ Lighthouse audit failed" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Summary
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Performance Test Summary" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

$results | Format-Table -AutoSize Url, Performance, Accessibility, BestPractices, SEO

# Comparison if both before and after exist
if ($Compare -and $Urls.Count -eq 1) {
    $url = $Urls[0]
    $urlHash = $url -replace '[^a-zA-Z0-9]', '-'
    $beforeFile = "test-results/lighthouse/lighthouse-$urlHash-before.json"
    $afterFile = "test-results/lighthouse/lighthouse-$urlHash-after.json"
    
    if ((Test-Path $beforeFile) -and (Test-Path $afterFile)) {
        Write-Host ""
        Write-Host "=" * 80 -ForegroundColor Cyan
        Write-Host "Before vs After Comparison" -ForegroundColor Cyan
        Write-Host "=" * 80 -ForegroundColor Cyan
        Write-Host ""
        
        $before = Get-Content $beforeFile -Raw | ConvertFrom-Json
        $after = Get-Content $afterFile -Raw | ConvertFrom-Json
        
        function Get-ScoreDiff($before, $after) {
            $diff = $after - $before
            $sign = if ($diff -gt 0) { '+' } else { '' }
            $color = if ($diff -gt 0) { 'Green' } elseif ($diff -lt 0) { 'Red' } else { 'Gray' }
            return @{ Text = "$sign$diff"; Color = $color }
        }
        
        $perfDiff = Get-ScoreDiff ($before.categories.performance.score * 100) ($after.categories.performance.score * 100)
        $a11yDiff = Get-ScoreDiff ($before.categories.accessibility.score * 100) ($after.categories.accessibility.score * 100)
        $bpDiff = Get-ScoreDiff ($before.categories.'best-practices'.score * 100) ($after.categories.'best-practices'.score * 100)
        $seoDiff = Get-ScoreDiff ($before.categories.seo.score * 100) ($after.categories.seo.score * 100)
        
        Write-Host "Performance:    " -NoNewline
        Write-Host "$([math]::Round($before.categories.performance.score * 100)) → $([math]::Round($after.categories.performance.score * 100)) " -NoNewline
        Write-Host "($($perfDiff.Text))" -ForegroundColor $perfDiff.Color
        
        Write-Host "Accessibility:  " -NoNewline
        Write-Host "$([math]::Round($before.categories.accessibility.score * 100)) → $([math]::Round($after.categories.accessibility.score * 100)) " -NoNewline
        Write-Host "($($a11yDiff.Text))" -ForegroundColor $a11yDiff.Color
        
        Write-Host "Best Practices: " -NoNewline
        Write-Host "$([math]::Round($before.categories.'best-practices'.score * 100)) → $([math]::Round($after.categories.'best-practices'.score * 100)) " -NoNewline
        Write-Host "($($bpDiff.Text))" -ForegroundColor $bpDiff.Color
        
        Write-Host "SEO:            " -NoNewline
        Write-Host "$([math]::Round($before.categories.seo.score * 100)) → $([math]::Round($after.categories.seo.score * 100)) " -NoNewline
        Write-Host "($($seoDiff.Text))" -ForegroundColor $seoDiff.Color
        
        Write-Host ""
    } else {
        Write-Host "To compare before/after, run:" -ForegroundColor Yellow
        Write-Host "  .\scripts\test-performance.ps1 -Before" -ForegroundColor Cyan
        Write-Host "  <make CSS changes>" -ForegroundColor Gray
        Write-Host "  .\scripts\test-performance.ps1 -After" -ForegroundColor Cyan
        Write-Host "  .\scripts\test-performance.ps1 -Compare" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "✓ Performance testing complete" -ForegroundColor Green
Write-Host ""
