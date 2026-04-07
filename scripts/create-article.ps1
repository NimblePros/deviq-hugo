# Script to create a new DevIQ article using the default archetype
# Usage: .\create-article.ps1
# Or: .\create-article.ps1 -Title "My Article" -Category "principles"

param(
    [Parameter(Mandatory=$false)]
    [string]$Title,

    [Parameter(Mandatory=$false)]
    [string]$Category
)

Write-Host "`n=== DevIQ Article Creator ===" -ForegroundColor Cyan
Write-Host ""

# Discover available categories (subdirectories under content/, excluding files)
$contentPath = Join-Path $PSScriptRoot "..\content"
$categories = Get-ChildItem -Path $contentPath -Directory | Select-Object -ExpandProperty Name | Sort-Object

# Prompt for category if not provided
if ([string]::IsNullOrWhiteSpace($Category)) {
    Write-Host "Available categories:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $categories.Count; $i++) {
        Write-Host "  $($i + 1). $($categories[$i])"
    }
    Write-Host ""

    $categoryInput = $null
    do {
        $categoryInput = Read-Host "Select a category by number or name (required)"

        # Accept numeric selection
        if ($categoryInput -match '^\d+$') {
            $index = [int]$categoryInput - 1
            if ($index -ge 0 -and $index -lt $categories.Count) {
                $Category = $categories[$index]
            } else {
                Write-Host "  Invalid number. Please enter a number between 1 and $($categories.Count)." -ForegroundColor Red
                $categoryInput = $null
            }
        } elseif ($categories -contains $categoryInput) {
            $Category = $categoryInput
        } else {
            Write-Host "  '$categoryInput' is not a valid category. Please choose from the list." -ForegroundColor Red
            $categoryInput = $null
        }
    } while ([string]::IsNullOrWhiteSpace($Category))

    Write-Host ""
}

# Validate category
if ($categories -notcontains $Category) {
    Write-Host "ERROR: '$Category' is not a valid content category." -ForegroundColor Red
    Write-Host "Valid categories: $($categories -join ', ')" -ForegroundColor Yellow
    exit 1
}

# Prompt for title if not provided
if ([string]::IsNullOrWhiteSpace($Title)) {
    do {
        $Title = Read-Host "Article title (required)"
    } while ([string]::IsNullOrWhiteSpace($Title))
    Write-Host ""
}

# Normalize title to a slug
$slug = $Title.ToLower() -replace '[^a-z0-9\s-]', '' -replace '\s+', '-' -replace '-+', '-'

# Locate the hugo executable
$hugoCmd = $null
if (Get-Command hugo -ErrorAction SilentlyContinue) {
    $hugoCmd = "hugo"
} else {
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

# Run hugo new from the repo root so archetypes resolve correctly
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $repoRoot

$contentRelPath = "content/$Category/$slug.md"
Write-Host "Creating article: $contentRelPath" -ForegroundColor Green
& $hugoCmd new $contentRelPath

$exitCode = $LASTEXITCODE
Pop-Location

if ($exitCode -ne 0) {
    Write-Host "Failed to create article. See error above." -ForegroundColor Red
    exit 1
}

$articlePath = Join-Path $repoRoot "content\$Category\$slug.md"
Write-Host "`nArticle created at: content\$Category\$slug.md" -ForegroundColor Cyan

# Ask whether to publish and add to _index.md
Write-Host ""
$publishInput = Read-Host "Add to _index.md and mark as published? (y/N)"
if ($publishInput -eq 'y' -or $publishInput -eq 'Y') {

    # Remove draft flag from the new article
    $content = Get-Content $articlePath -Raw
    $content = $content -replace 'draft: true', 'draft: false'
    Set-Content $articlePath -Value $content -NoNewline

    # Insert entry into _index.md alphabetically within the bullet list
    $indexPath = Join-Path $repoRoot "content/$Category/_index.md"
    if (Test-Path $indexPath) {
        $newEntry = "- [$Title](/$Category/$slug/)"
        $lines = (Get-Content $indexPath) # array of lines

        # Find indices of all bullet list lines
        $listIndices = @()
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^- \[') {
                $listIndices += $i
            }
        }

        if ($listIndices.Count -eq 0) {
            # No existing list — append to file
            Add-Content $indexPath "`n$newEntry"
            Write-Host "Appended entry to _index.md (no existing list found)." -ForegroundColor Yellow
        } else {
            # Find alphabetical insertion point by display title
            $insertBefore = -1
            foreach ($idx in $listIndices) {
                if ($lines[$idx] -match '^- \[([^\]]+)\]') {
                    if ([string]::Compare($Title, $Matches[1], $true) -lt 0) {
                        $insertBefore = $idx
                        break
                    }
                }
            }

            if ($insertBefore -eq -1) {
                # Append after the last list entry
                $last = $listIndices[-1]
                $lines = $lines[0..$last] + $newEntry + ($last + 1 -lt $lines.Count ? $lines[($last + 1)..($lines.Count - 1)] : @())
            } else {
                $before = $insertBefore - 1 -ge 0 ? $lines[0..($insertBefore - 1)] : @()
                $lines = $before + $newEntry + $lines[$insertBefore..($lines.Count - 1)]
            }

            Set-Content $indexPath -Value $lines
            Write-Host "Added '$Title' to _index.md." -ForegroundColor Green
        }
    } else {
        Write-Host "WARNING: _index.md not found at $indexPath — skipping index update." -ForegroundColor Yellow
    }

    # Update weights for the category
    $weightsScript = Join-Path $repoRoot "scripts/updateweights.cs"
    $categoryContentPath = Join-Path $repoRoot "content/$Category"
    Write-Host "Updating weights in content/$Category..." -ForegroundColor Green
    & dotnet $weightsScript $categoryContentPath
}

# Open in VS Code if available
Write-Host ""
if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Host "Opening in VS Code..." -ForegroundColor Cyan
    code $articlePath
} else {
    Write-Host "VS Code not found in PATH. Please open the file manually." -ForegroundColor Yellow
}
