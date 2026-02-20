# CSS Testing Setup Script
# Run this script to set up all testing tools for CSS refactoring

param(
    [switch]$SkipInstall = $false
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "CSS Refactoring - Testing Setup" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# Check Node.js installation
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "✗ Node.js not found!" -ForegroundColor Red
    Write-Host "  Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

$nodeVersion = node --version
Write-Host "✓ Node.js found: $nodeVersion" -ForegroundColor Green

# Check if npm is available
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "✗ npm not found!" -ForegroundColor Red
    exit 1
}

$npmVersion = npm --version
Write-Host "✓ npm found: $npmVersion" -ForegroundColor Green
Write-Host ""

# Install testing tools
if (-not $SkipInstall) {
    Write-Host "Installing testing tools..." -ForegroundColor Yellow
    Write-Host ""
    
    # Check if package.json exists
    if (-not (Test-Path "package.json")) {
        Write-Host "Creating package.json..." -ForegroundColor Cyan
        npm init -y
    }
    
    Write-Host "Installing BackstopJS for visual regression testing..." -ForegroundColor Cyan
    npm install --save-dev backstopjs
    
    Write-Host "Installing stylelint for CSS validation..." -ForegroundColor Cyan
    npm install --save-dev stylelint stylelint-config-standard
    
    Write-Host "Installing pa11y for accessibility testing..." -ForegroundColor Cyan
    npm install --save-dev pa11y
    
    Write-Host "Installing lighthouse for performance testing..." -ForegroundColor Cyan
    npm install --save-dev lighthouse
    
    Write-Host ""
    Write-Host "✓ All testing tools installed" -ForegroundColor Green
}

# Create .stylelintrc.json if it doesn't exist
if (-not (Test-Path ".stylelintrc.json")) {
    Write-Host "Creating .stylelintrc.json configuration..." -ForegroundColor Cyan
    
    $stylelintConfig = @{
        "extends" = "stylelint-config-standard"
        "rules" = @{
            "selector-class-pattern" = $null
            "custom-property-pattern" = $null
            "no-descending-specificity" = $null
            "declaration-block-no-redundant-longhand-properties" = $null
            "color-function-notation" = "legacy"
        }
    } | ConvertTo-Json -Depth 10
    
    $stylelintConfig | Out-File -FilePath ".stylelintrc.json" -Encoding UTF8
    Write-Host "✓ Created .stylelintrc.json" -ForegroundColor Green
}

# Initialize BackstopJS if not already done
if (-not (Test-Path "backstop.json")) {
    Write-Host ""
    Write-Host "Initializing BackstopJS..." -ForegroundColor Cyan
    npx backstopjs init
    Write-Host "✓ BackstopJS initialized" -ForegroundColor Green
    Write-Host ""
    Write-Host "NOTE: Edit backstop.json to add your site URLs before running tests" -ForegroundColor Yellow
}

# Create testing directories
Write-Host ""
Write-Host "Creating testing directories..." -ForegroundColor Cyan
$dirs = @("test-results", "test-results/screenshots", "test-results/lighthouse", "test-results/accessibility")
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Created $dir" -ForegroundColor Gray
    }
}
Write-Host "✓ Testing directories ready" -ForegroundColor Green

# Add .gitignore entries
Write-Host ""
Write-Host "Updating .gitignore..." -ForegroundColor Cyan
$gitignoreEntries = @"

# Testing tools
node_modules/
backstop_data/
test-results/
.stylelintcache
lighthouse-*.json
"@

if (Test-Path ".gitignore") {
    $currentGitignore = Get-Content ".gitignore" -Raw
    if ($currentGitignore -notmatch "backstop_data") {
        Add-Content ".gitignore" $gitignoreEntries
        Write-Host "✓ Updated .gitignore" -ForegroundColor Green
    } else {
        Write-Host "✓ .gitignore already configured" -ForegroundColor Green
    }
} else {
    $gitignoreEntries | Out-File -FilePath ".gitignore" -Encoding UTF8
    Write-Host "✓ Created .gitignore" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Start Hugo server: " -ForegroundColor White -NoNewline
Write-Host "hugo server" -ForegroundColor Cyan
Write-Host "  2. Edit backstop.json to configure test scenarios" -ForegroundColor White
Write-Host "  3. Run baseline capture: " -ForegroundColor White -NoNewline
Write-Host ".\scripts\test-baseline.ps1" -ForegroundColor Cyan
Write-Host "  4. Make CSS changes in style-v2.css" -ForegroundColor White
Write-Host "  5. Run visual regression: " -ForegroundColor White -NoNewline
Write-Host ".\scripts\test-visual-regression.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available testing scripts:" -ForegroundColor Yellow
Write-Host "  .\scripts\test-baseline.ps1           - Capture reference screenshots" -ForegroundColor Gray
Write-Host "  .\scripts\test-visual-regression.ps1  - Compare current vs reference" -ForegroundColor Gray
Write-Host "  .\scripts\test-css-validation.ps1     - Validate CSS syntax" -ForegroundColor Gray
Write-Host "  .\scripts\test-accessibility.ps1      - Run a11y tests" -ForegroundColor Gray
Write-Host "  .\scripts\test-performance.ps1        - Run Lighthouse audit" -ForegroundColor Gray
Write-Host "  .\scripts\test-all.ps1                - Run all tests" -ForegroundColor Gray
Write-Host ""
