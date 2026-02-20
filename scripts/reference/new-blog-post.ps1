# Script to create a new blog post using Hugo archetypes
# Usage: .\new-blog-post.ps1 "my-new-post-title"
# Or run without parameters for interactive mode

param(
    [Parameter(Mandatory=$false)]
    [string]$Title,
    
    [Parameter(Mandatory=$false)]
    [string]$Description,
    
    [Parameter(Mandatory=$false)]
    [string[]]$Categories,
    
    [Parameter(Mandatory=$false)]
    [string[]]$Tags,
    
    [Parameter(Mandatory=$false)]
    [switch]$Draft
)

# Interactive mode if no title provided
if ([string]::IsNullOrWhiteSpace($Title)) {
    Write-Host "`n=== New Blog Post Creator ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Title (required)
    do {
        $Title = Read-Host "Post Title (required)"
    } while ([string]::IsNullOrWhiteSpace($Title))
    
    # Description (optional but recommended)
    Write-Host ""
    $descInput = Read-Host "Description (optional, but recommended for SEO)"
    if (-not [string]::IsNullOrWhiteSpace($descInput)) {
        $Description = $descInput
    }
    
    # Categories (optional)
    Write-Host ""
    $catInput = Read-Host "Categories (comma-separated, optional)"
    if (-not [string]::IsNullOrWhiteSpace($catInput)) {
        $Categories = $catInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    }
    
    # Tags (optional)
    Write-Host ""
    $tagInput = Read-Host "Tags (comma-separated, optional)"
    if (-not [string]::IsNullOrWhiteSpace($tagInput)) {
        $Tags = $tagInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    }
    
    # Draft status (optional)
    Write-Host ""
    $draftInput = Read-Host "Create as draft? (y/N)"
    if ($draftInput -eq 'y' -or $draftInput -eq 'Y') {
        $Draft = $true
    }
    
    Write-Host ""
}

# Normalize the title to a slug format
$slug = $Title.ToLower() -replace '[^a-z0-9\s-]', '' -replace '\s+', '-'

# Try to find hugo executable
$hugoCmd = $null
if (Get-Command hugo -ErrorAction SilentlyContinue) {
    $hugoCmd = "hugo"
} else {
    # Check winget installation location
    $wingetHugo = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Hugo.Hugo.Extended_Microsoft.Winget.Source_8wekyb3d8bbwe\hugo.exe"
    if (Test-Path $wingetHugo) {
        $hugoCmd = $wingetHugo
    } else {
        Write-Host "ERROR: Hugo is not installed or not found in PATH." -ForegroundColor Red
        Write-Host "Please install Hugo using: winget install Hugo.Hugo.Extended" -ForegroundColor Yellow
        Write-Host "Then restart your terminal." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "Creating new blog post: $slug" -ForegroundColor Green
& $hugoCmd new "content/blog/$slug.md"

if ($LASTEXITCODE -eq 0) {
    $postPath = "content\blog\$slug.md"
    
    # Update frontmatter with custom values if provided
    $content = Get-Content $postPath -Raw
    
    if (-not [string]::IsNullOrWhiteSpace($Description)) {
        $content = $content -replace 'description: "A brief description of your post \(used for SEO and social sharing\)"', "description: `"$Description`""
    }
    
    if ($Categories -and $Categories.Count -gt 0) {
        $catArray = ($Categories | ForEach-Object { "`"$_`"" }) -join ", "
        $content = $content -replace 'categories: \[\]', "categories: [$catArray]"
    }
    
    if ($Tags -and $Tags.Count -gt 0) {
        $tagArray = ($Tags | ForEach-Object { "`"$_`"" }) -join ", "
        $content = $content -replace 'tags: \[\]', "tags: [$tagArray]"
    }
    
    if ($Draft) {
        $content = $content -replace 'draft: false', 'draft: true'
    }
    
    Set-Content $postPath -Value $content -NoNewline
    
    Write-Host "`nNew blog post created at: $postPath" -ForegroundColor Cyan
    Write-Host "Opening file..." -ForegroundColor Cyan

    # Open in VS Code if available
    if (Get-Command code -ErrorAction SilentlyContinue) {
        code $postPath
    } else {
        Write-Host "VS Code not found in PATH. Please open the file manually." -ForegroundColor Yellow
    }
} else {
    Write-Host "Failed to create blog post. See error above." -ForegroundColor Red
}
