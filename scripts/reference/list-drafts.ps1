Write-Host "Current Drafts:" -ForegroundColor Cyan
Write-Host ""

Get-ChildItem -Path "content/blog" -Filter "*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "(?m)^draft:\s*true") {
        $title = if ($content -match "(?m)^title:\s*[`"']?(.+?)[`"']?$") { $matches[1] } else { $_.BaseName }
        $date = if ($content -match "(?m)^date:\s*[`"']?(.+?)[`"']?$") { $matches[1] } else { "No date" }
        
        Write-Host "📝 $title" -ForegroundColor Yellow
        Write-Host "   File: $($_.Name)" -ForegroundColor Gray
        Write-Host "   Date: $date" -ForegroundColor Gray
        Write-Host ""
    }
}
