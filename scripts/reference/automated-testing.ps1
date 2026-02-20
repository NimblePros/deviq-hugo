# Automated Testing Script for ardalis.com
# Automates 9 out of 12 items from the Testing Checklist
#
# Prerequisites:
# - npm install -g lighthouse
# - npm install -g broken-link-checker
# - Hugo server running or deployed site URL

param(
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl = "https://ardalis.com",
    
    [switch]$SkipLighthouse,
    [switch]$SkipLinkCheck,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$results = @{
    Passed = @()
    Failed = @()
    Warnings = @()
}

function Write-TestHeader {
    param([string]$Message)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Write-TestResult {
    param(
        [string]$Test,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    if ($Passed) {
        Write-Host "✓ $Test" -ForegroundColor Green
        $results.Passed += $Test
    } else {
        Write-Host "✗ $Test" -ForegroundColor Red
        $results.Failed += $Test
    }
    
    if ($Message) {
        Write-Host "  $Message" -ForegroundColor Gray
    }
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
    $results.Warnings += $Message
}

# =============================================================================
# 1. VALIDATE OPEN GRAPH METADATA
# =============================================================================
Write-TestHeader "1. Validating Open Graph Metadata"

try {
    $testUrl = "$SiteUrl/blog"
    $response = Invoke-WebRequest -Uri $testUrl -UseBasicParsing -TimeoutSec 10
    $html = $response.Content
    
    $ogTags = @(
        'og:title',
        'og:description',
        'og:url',
        'og:type',
        'og:image'
    )
    
    $missingTags = @()
    foreach ($tag in $ogTags) {
        if ($html -notmatch "property=`"$tag`"") {
            $missingTags += $tag
        }
    }
    
    if ($missingTags.Count -eq 0) {
        Write-TestResult "Open Graph metadata present" $true
    } else {
        Write-TestResult "Open Graph metadata" $false "Missing: $($missingTags -join ', ')"
    }
    
    # API validation (opengraph.xyz doesn't have public API, but we can check structure)
    if ($Verbose) {
        Write-Host "`nOpen Graph tags found:" -ForegroundColor Gray
        [regex]::Matches($html, '<meta property="og:([^"]+)" content="([^"]+)"') | ForEach-Object {
            Write-Host "  og:$($_.Groups[1].Value) = $($_.Groups[2].Value)" -ForegroundColor DarkGray
        }
    }
    
} catch {
    Write-TestResult "Open Graph validation" $false $_.Exception.Message
}

# =============================================================================
# 2. VALIDATE TWITTER CARD METADATA
# =============================================================================
Write-TestHeader "2. Validating Twitter Card Metadata"

try {
    $twitterTags = @(
        'twitter:card',
        'twitter:title',
        'twitter:description',
        'twitter:image'
    )
    
    $missingTwitterTags = @()
    foreach ($tag in $twitterTags) {
        if ($html -notmatch "name=`"$tag`"") {
            $missingTwitterTags += $tag
        }
    }
    
    if ($missingTwitterTags.Count -eq 0) {
        Write-TestResult "Twitter Card metadata present" $true
    } else {
        Write-TestResult "Twitter Card metadata" $false "Missing: $($missingTwitterTags -join ', ')"
    }
    
    if ($Verbose) {
        Write-Host "`nTwitter Card tags found:" -ForegroundColor Gray
        [regex]::Matches($html, '<meta name="twitter:([^"]+)" content="([^"]+)"') | ForEach-Object {
            Write-Host "  twitter:$($_.Groups[1].Value) = $($_.Groups[2].Value)" -ForegroundColor DarkGray
        }
    }
    
} catch {
    Write-TestResult "Twitter Card validation" $false $_.Exception.Message
}

# =============================================================================
# 3. VALIDATE STRUCTURED DATA (Schema.org)
# =============================================================================
Write-TestHeader "3. Validating Structured Data (Schema.org)"

try {
    # Check for JSON-LD
    if ($html -match '<script type="application/ld\+json">') {
        $jsonLdMatches = [regex]::Matches($html, '<script type="application/ld\+json">(.*?)</script>')
        
        $validSchemas = 0
        $invalidSchemas = 0
        
        foreach ($match in $jsonLdMatches) {
            try {
                $jsonContent = $match.Groups[1].Value.Trim()
                $schema = $jsonContent | ConvertFrom-Json
                
                if ($schema.'@context' -match 'schema.org') {
                    $validSchemas++
                    if ($Verbose) {
                        Write-Host "  Found @type: $($schema.'@type')" -ForegroundColor DarkGray
                    }
                }
            } catch {
                $invalidSchemas++
            }
        }
        
        if ($validSchemas -gt 0) {
            Write-TestResult "Structured data present" $true "$validSchemas schema(s) found"
        } else {
            Write-TestResult "Structured data" $false "No valid schemas found"
        }
    } else {
        Write-TestResult "Structured data" $false "No JSON-LD structured data found"
    }
    
} catch {
    Write-TestResult "Structured data validation" $false $_.Exception.Message
}

# =============================================================================
# 4. RUN LIGHTHOUSE AUDIT
# =============================================================================
if (-not $SkipLighthouse) {
    Write-TestHeader "4. Running Lighthouse Audit"
    
    try {
        # Check if lighthouse is installed
        $lighthouseCmd = Get-Command lighthouse -ErrorAction SilentlyContinue
        
        if ($lighthouseCmd) {
            $outputFile = "lighthouse-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
            
            Write-Host "Running Lighthouse (this may take 30-60 seconds)..." -ForegroundColor Yellow
            
            $lighthouseResult = & lighthouse $SiteUrl `
                --only-categories=performance,accessibility,best-practices,seo `
                --output=json `
                --output-path=$outputFile `
                --chrome-flags="--headless" `
                --quiet 2>&1
            
            if (Test-Path $outputFile) {
                $report = Get-Content $outputFile | ConvertFrom-Json
                
                $scores = @{
                    Performance = [math]::Round($report.categories.performance.score * 100)
                    Accessibility = [math]::Round($report.categories.accessibility.score * 100)
                    BestPractices = [math]::Round($report.categories.'best-practices'.score * 100)
                    SEO = [math]::Round($report.categories.seo.score * 100)
                }
                
                Write-Host "`nLighthouse Scores:" -ForegroundColor Cyan
                foreach ($category in $scores.Keys) {
                    $score = $scores[$category]
                    $color = if ($score -ge 90) { "Green" } elseif ($score -ge 70) { "Yellow" } else { "Red" }
                    Write-Host "  $category : $score" -ForegroundColor $color
                }
                
                $allPassed = ($scores.Values | Where-Object { $_ -lt 90 }).Count -eq 0
                Write-TestResult "Lighthouse audit (90+ scores)" $allPassed
                
                Write-Host "`nFull report saved to: $outputFile" -ForegroundColor Gray
            } else {
                Write-TestResult "Lighthouse audit" $false "Report file not generated"
            }
        } else {
            Write-Warning "Lighthouse not found. Install with: npm install -g lighthouse"
            Write-TestResult "Lighthouse audit" $false "Tool not installed"
        }
    } catch {
        Write-TestResult "Lighthouse audit" $false $_.Exception.Message
    }
} else {
    Write-Host "Skipping Lighthouse audit (--SkipLighthouse flag)" -ForegroundColor Yellow
}

# =============================================================================
# 5. VERIFY RSS FEED
# =============================================================================
Write-TestHeader "5. Validating RSS Feed"

try {
    $rssUrl = "$SiteUrl/blog/index.xml"
    $rssResponse = Invoke-WebRequest -Uri $rssUrl -UseBasicParsing -TimeoutSec 10
    
    if ($rssResponse.StatusCode -eq 200) {
        [xml]$rssFeed = $rssResponse.Content
        
        # Check RSS structure
        $hasChannel = $null -ne $rssFeed.rss.channel
        $hasTitle = $null -ne $rssFeed.rss.channel.title
        $hasItems = ($rssFeed.rss.channel.item | Measure-Object).Count -gt 0
        
        if ($hasChannel -and $hasTitle -and $hasItems) {
            $itemCount = ($rssFeed.rss.channel.item | Measure-Object).Count
            Write-TestResult "RSS feed valid" $true "$itemCount items found"
            
            if ($Verbose) {
                Write-Host "`nRecent RSS items:" -ForegroundColor Gray
                $rssFeed.rss.channel.item | Select-Object -First 3 | ForEach-Object {
                    Write-Host "  - $($_.title)" -ForegroundColor DarkGray
                }
            }
        } else {
            Write-TestResult "RSS feed structure" $false "Invalid RSS structure"
        }
    } else {
        Write-TestResult "RSS feed" $false "HTTP $($rssResponse.StatusCode)"
    }
    
} catch {
    Write-TestResult "RSS feed validation" $false $_.Exception.Message
}

# =============================================================================
# 6. CHECK NAVIGATION LINKS (BROKEN LINK CHECK)
# =============================================================================
if (-not $SkipLinkCheck) {
    Write-TestHeader "6. Checking Navigation Links"
    
    try {
        # Check if broken-link-checker is installed
        $blcCmd = Get-Command blc -ErrorAction SilentlyContinue
        
        if ($blcCmd) {
            Write-Host "Checking all links (this may take 1-2 minutes)..." -ForegroundColor Yellow
            
            # Run broken-link-checker
            $blcOutput = & blc $SiteUrl --recursive --ordered --exclude "linkedin.com|facebook.com|twitter.com|disqus.com" 2>&1
            
            # Parse output for broken links
            $brokenCount = 0
            if ($blcOutput -match "(\d+) broken") {
                $brokenCount = [int]$matches[1]
            }
            
            if ($brokenCount -eq 0) {
                Write-TestResult "Navigation links" $true "No broken links found"
            } else {
                Write-TestResult "Navigation links" $false "$brokenCount broken link(s) found"
                if ($Verbose) {
                    Write-Host "`nBroken links:" -ForegroundColor Gray
                    $blcOutput | Select-String "BROKEN" | ForEach-Object {
                        Write-Host "  $_" -ForegroundColor DarkGray
                    }
                }
            }
        } else {
            Write-Warning "broken-link-checker not found. Install with: npm install -g broken-link-checker"
            
            # Fallback: Check main navigation links manually
            Write-Host "Performing basic navigation check..." -ForegroundColor Yellow
            
            $navLinks = @(
                "$SiteUrl/",
                "$SiteUrl/blog",
                "$SiteUrl/about",
                "$SiteUrl/contact",
                "$SiteUrl/books",
                "$SiteUrl/training-classes",
                "$SiteUrl/mentoring"
            )
            
            $failedLinks = @()
            foreach ($link in $navLinks) {
                try {
                    $response = Invoke-WebRequest -Uri $link -UseBasicParsing -TimeoutSec 5 -Method Head
                    if ($response.StatusCode -ne 200) {
                        $failedLinks += "$link (HTTP $($response.StatusCode))"
                    }
                } catch {
                    $failedLinks += "$link (Failed)"
                }
            }
            
            if ($failedLinks.Count -eq 0) {
                Write-TestResult "Main navigation links" $true "All main links working"
            } else {
                Write-TestResult "Main navigation links" $false "$($failedLinks.Count) link(s) failed"
                $failedLinks | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkGray }
            }
        }
    } catch {
        Write-TestResult "Link checking" $false $_.Exception.Message
    }
} else {
    Write-Host "Skipping link checking (--SkipLinkCheck flag)" -ForegroundColor Yellow
}

# =============================================================================
# 7. VALIDATE HTML
# =============================================================================
Write-TestHeader "7. Validating HTML (W3C)"

try {
    # W3C Validator API
    $validatorUrl = "https://validator.w3.org/nu/?out=json"
    
    Write-Host "Validating HTML with W3C Validator..." -ForegroundColor Yellow
    
    $htmlResponse = Invoke-WebRequest -Uri $SiteUrl -UseBasicParsing -TimeoutSec 10
    $htmlContent = $htmlResponse.Content
    
    # Note: W3C API has rate limits and requires proper headers
    try {
        $validationResponse = Invoke-RestMethod -Uri $validatorUrl `
            -Method Post `
            -ContentType "text/html; charset=utf-8" `
            -Body $htmlContent `
            -TimeoutSec 15
        
        $errors = ($validationResponse.messages | Where-Object { $_.type -eq "error" }).Count
        $warnings = ($validationResponse.messages | Where-Object { $_.type -eq "warning" }).Count
        
        if ($errors -eq 0) {
            Write-TestResult "HTML validation" $true "$warnings warning(s)"
        } else {
            Write-TestResult "HTML validation" $false "$errors error(s), $warnings warning(s)"
            
            if ($Verbose -and $errors -gt 0) {
                Write-Host "`nValidation errors:" -ForegroundColor Gray
                $validationResponse.messages | Where-Object { $_.type -eq "error" } | Select-Object -First 5 | ForEach-Object {
                    Write-Host "  Line $($_.lastLine): $($_.message)" -ForegroundColor DarkGray
                }
            }
        }
    } catch {
        Write-Warning "W3C Validator API request failed (rate limit or network issue)"
        Write-TestResult "HTML validation" $false "API unavailable - manual check required"
    }
    
} catch {
    Write-TestResult "HTML validation" $false $_.Exception.Message
}

# =============================================================================
# 8. TEST SEARCH FUNCTIONALITY (Basic Check)
# =============================================================================
Write-TestHeader "8. Testing Search Functionality"

try {
    # Check if search page exists
    $searchUrl = "$SiteUrl/search"
    $searchResponse = Invoke-WebRequest -Uri $searchUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
    
    if ($searchResponse.StatusCode -eq 200) {
        # Check for common search indicators
        $hasSearchBox = $searchResponse.Content -match 'type="search"|class="search"|id="search"'
        $hasPagefind = $searchResponse.Content -match 'pagefind'
        
        if ($hasSearchBox -or $hasPagefind) {
            Write-TestResult "Search functionality present" $true
            Write-Host "  Note: Manual testing required for search accuracy" -ForegroundColor Gray
        } else {
            Write-TestResult "Search page" $true "Page exists but search UI not detected"
        }
    } else {
        Write-TestResult "Search functionality" $false "Search page not found (404)"
    }
    
} catch {
    Write-TestResult "Search functionality" $false "No search page found"
}

# =============================================================================
# 9. BASIC MULTI-BROWSER CHECK (Using User-Agents)
# =============================================================================
Write-TestHeader "9. Multi-Browser Compatibility Check"

try {
    Write-Host "Testing with different user agents..." -ForegroundColor Yellow
    
    $userAgents = @{
        "Chrome" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        "Firefox" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0"
        "Safari" = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15"
        "Edge" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0.0"
    }
    
    $allPassed = $true
    foreach ($browser in $userAgents.Keys) {
        try {
            $response = Invoke-WebRequest -Uri $SiteUrl -UserAgent $userAgents[$browser] -UseBasicParsing -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Host "  ✓ $browser" -ForegroundColor Green
            } else {
                Write-Host "  ✗ $browser (HTTP $($response.StatusCode))" -ForegroundColor Red
                $allPassed = $false
            }
        } catch {
            Write-Host "  ✗ $browser (Failed)" -ForegroundColor Red
            $allPassed = $false
        }
    }
    
    Write-TestResult "Multi-browser user-agent test" $allPassed
    Write-Host "  Note: This only tests user-agent acceptance. Full browser testing required." -ForegroundColor Gray
    
} catch {
    Write-TestResult "Multi-browser check" $false $_.Exception.Message
}

# =============================================================================
# SUMMARY REPORT
# =============================================================================
Write-Host "`n`n========================================" -ForegroundColor Magenta
Write-Host "AUTOMATED TEST SUMMARY" -ForegroundColor Magenta
Write-Host "========================================`n" -ForegroundColor Magenta

Write-Host "✓ Passed Tests: $($results.Passed.Count)" -ForegroundColor Green
$results.Passed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }

if ($results.Failed.Count -gt 0) {
    Write-Host "`n✗ Failed Tests: $($results.Failed.Count)" -ForegroundColor Red
    $results.Failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

if ($results.Warnings.Count -gt 0) {
    Write-Host "`n⚠ Warnings: $($results.Warnings.Count)" -ForegroundColor Yellow
    $results.Warnings | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

Write-Host "`n----------------------------------------" -ForegroundColor Magenta
Write-Host "MANUAL TESTING STILL REQUIRED:" -ForegroundColor Yellow
Write-Host "  - Test on real mobile devices (iOS & Android)" -ForegroundColor Gray
Write-Host "  - Full keyboard navigation testing" -ForegroundColor Gray
Write-Host "  - Screen reader testing (NVDA/JAWS/VoiceOver)" -ForegroundColor Gray
Write-Host "  - Visual/UX validation in browsers" -ForegroundColor Gray
Write-Host "========================================`n" -ForegroundColor Magenta

# Exit code based on failures
if ($results.Failed.Count -gt 0) {
    exit 1
} else {
    exit 0
}
