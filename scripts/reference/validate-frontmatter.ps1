# Validate blog post frontmatter
param(
    [string]$Path = "content/blog"
)

$required = @('title', 'date', 'description', 'featuredImage')
$issues = @()

Get-ChildItem -Path $Path -Filter "*.md" | Where-Object { $_.Name -ne "_index.md" } | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    
    # Extract frontmatter (content between --- markers)
    if ($content -match '(?s)^---\s*\r?\n(.*?)\r?\n---') {
        $frontmatter = $Matches[1]
        
        foreach ($field in $required) {
            if ($frontmatter -notmatch "(?m)^$field\s*:") {
                $issues += "$($_.Name) missing: $field"
            }
        }
        
        # Check for empty description (matches "description: " or "description:" followed by newline)
        if ($frontmatter -match "(?m)^description:\s*(\r?\n|$)") {
            $issues += "$($_.Name) has empty description"
        }
    } else {
        $issues += "$($_.Name) has invalid or missing frontmatter"
    }
}

if ($issues.Count -gt 0) {
    Write-Host "Frontmatter Issues Found:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    exit 1
} else {
    Write-Host "All frontmatter valid!" -ForegroundColor Green
}
