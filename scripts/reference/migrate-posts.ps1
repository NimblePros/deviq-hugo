# Script to migrate blog posts from Gatsby to Hugo
$gatsbyBlogPath = "..\nimblepros-blog-gatsby\content\blog"
$hugoBlogPath = ".\content\posts"

# Get all blog post directories
$blogPosts = Get-ChildItem $gatsbyBlogPath -Directory

Write-Host "Found $($blogPosts.Count) blog posts to migrate..."

$migratedCount = 0
$skippedCount = 0

foreach ($post in $blogPosts) {
    $sourcePath = Join-Path $gatsbyBlogPath $post.Name
    $destPath = Join-Path $hugoBlogPath $post.Name
    
    # Check if the post already exists
    if (Test-Path $destPath) {
        Write-Host "Skipped (already exists): $($post.Name)" -ForegroundColor Yellow
        $skippedCount++
        continue
    }
    
    # Create destination directory
    New-Item -ItemType Directory -Path $destPath -Force | Out-Null
    
    # Copy the entire directory (including images)
    Copy-Item -Path "$sourcePath\*" -Destination $destPath -Recurse -Force
    
    Write-Host "Copied: $($post.Name)" -ForegroundColor Green
    $migratedCount++
}

Write-Host "`nMigration complete! $migratedCount posts copied, $skippedCount posts skipped."
