<#
.SYNOPSIS
  Unified image optimization script - converts images to WebP, updates markdown references, and removes originals.
.DESCRIPTION
  Combines the functionality of image-fix.ps1 and image-optimize-webp.ps1 into a single script.
  
  By default (Full Workflow mode):
   1. Finds PNG/JPG/JPEG/GIF images larger than the size threshold
   2. Converts them to optimized WebP (only if savings meet threshold)
   3. Updates all markdown references to use the new WebP image
   4. Removes the original image
  
  Use -ConvertOnly for just WebP generation without updating markdown or removing originals.
  
  Processes images in batches (default 10 per run) to allow review between batches.
  Requires ImageMagick 'magick' on PATH (auto-installs if missing on Windows).

.PARAMETER Root
  Root directory to scan (defaults to content/posts relative to repo root, where page bundle images live)
.PARAMETER SizeThreshold
  Size threshold in KB - only process images larger than this (default 100)
.PARAMETER MaxDimension
  Maximum width/height after resize (default 1600)
.PARAMETER Quality
  WebP quality setting (default 82, range 75-85 recommended)
.PARAMETER MinSavingsPercent
  Minimum percentage reduction to keep the WebP (default 10)
.PARAMETER MinSavingsKB
  Minimum KB reduction to keep the WebP (default 15). Either threshold qualifies.
.PARAMETER BatchSize
  Number of images to process per batch (default 10, use 0 for all)
.PARAMETER ConvertOnly
  Only create WebP files - don't update markdown or remove originals
.PARAMETER KeepOriginal
  Keep original files after conversion (only applies in full workflow mode)
.PARAMETER Force
  Re-process images even if WebP already exists
.PARAMETER IncludeGif
  Include GIF files in processing (converts first frame only)
.PARAMETER DryRun
  Show what would be done without making changes
.EXAMPLE
  # Preview what would be optimized
  pwsh ./optimize-images.ps1 -DryRun

.EXAMPLE
  # Process 10 images with full workflow (convert + update markdown + remove originals)
  pwsh ./optimize-images.ps1

.EXAMPLE
  # Process all images, keeping originals
  pwsh ./optimize-images.ps1 -BatchSize 0 -KeepOriginal

.EXAMPLE
  # Just create WebP files without updating markdown or removing originals
  pwsh ./optimize-images.ps1 -ConvertOnly

.EXAMPLE
  # More aggressive optimization with lower quality
  pwsh ./optimize-images.ps1 -Quality 75 -SizeThreshold 50

.EXAMPLE
  # Re-process all images including existing WebPs
  pwsh ./optimize-images.ps1 -Force -BatchSize 0
#>
[CmdletBinding()] param(
  [string]$Root,
  [int]$SizeThreshold = 100,
  [int]$MaxDimension = 1600,
  [int]$Quality = 82,
  [int]$MinSavingsPercent = 10,
  [int]$MinSavingsKB = 15,
  [int]$BatchSize = 10,
  [switch]$ConvertOnly,
  [switch]$KeepOriginal,
  [switch]$Force,
  [switch]$IncludeGif,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Root) { $Root = Join-Path $repoRoot 'content/posts' }
if (-not (Test-Path $Root)) { Write-Error "Root path not found: $Root" }

#region Helper Functions

function Ensure-ImageMagick {
  $magick = Get-Command magick -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($magick) { return $magick.Source }
  
  Write-Host "`nImageMagick not found. Attempting to install..." -ForegroundColor Yellow
  
  # Try WinGet first (modern Windows package manager)
  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if ($winget) {
    try {
      Write-Host "Installing ImageMagick via WinGet..." -ForegroundColor Cyan
      & winget install --id ImageMagick.ImageMagick -e --accept-source-agreements --accept-package-agreements
      
      # Refresh PATH
      $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
      
      $magick = Get-Command magick -ErrorAction SilentlyContinue
      if ($magick) {
        Write-Host "ImageMagick installed successfully!" -ForegroundColor Green
        return $magick.Source
      }
    } catch {
      Write-Host "WinGet installation failed; trying Chocolatey..." -ForegroundColor Yellow
    }
  }
  
  # Try Chocolatey as fallback
  $choco = Get-Command choco -ErrorAction SilentlyContinue
  if ($choco) {
    try {
      Write-Host "Installing ImageMagick via Chocolatey..." -ForegroundColor Cyan
      & choco install imagemagick -y
      
      $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
      $magick = Get-Command magick -ErrorAction SilentlyContinue
      if ($magick) {
        Write-Host "ImageMagick installed successfully!" -ForegroundColor Green
        return $magick.Source
      }
    } catch {
      Write-Host "Chocolatey installation failed." -ForegroundColor Yellow
    }
  }
  
  Write-Host @"

ImageMagick is required but could not be automatically installed.

Please install manually using one of these methods:

1. WinGet:  winget install --id ImageMagick.ImageMagick -e
2. Chocolatey:  choco install imagemagick -y
3. Direct: https://imagemagick.org/script/download.php#windows

After installation, restart PowerShell and run this script again.
"@ -ForegroundColor Red
  
  throw "ImageMagick installation required."
}

function Get-SavingsInfo {
  param([long]$OriginalBytes, [long]$NewBytes)
  
  $savedBytes = $OriginalBytes - $NewBytes
  $savedKB = [math]::Round($savedBytes / 1KB, 1)
  $percent = if ($OriginalBytes -gt 0) { [math]::Round(($savedBytes / $OriginalBytes) * 100, 1) } else { 0 }
  
  return @{
    SavedKB = $savedKB
    Percent = $percent
    MeetsThreshold = ($savedKB -ge $MinSavingsKB) -or ($percent -ge $MinSavingsPercent)
  }
}

#endregion

# Ensure ImageMagick is available
$magick = Ensure-ImageMagick

# Build file extension filter
$extensions = @('.png', '.jpg', '.jpeg')
if ($IncludeGif) { $extensions += '.gif' }

# Find candidate images
$allFiles = Get-ChildItem -Path $Root -Recurse -File | Where-Object { $extensions -contains $_.Extension.ToLower() }
if (-not $allFiles) { 
  Write-Host 'No matching image files found.' -ForegroundColor Yellow
  return 
}

# Filter to images above size threshold
$aboveThreshold = $allFiles | Where-Object { $_.Length / 1KB -gt $SizeThreshold } | Sort-Object Length -Descending

if (-not $aboveThreshold) { 
  Write-Host ("No images larger than {0} KB found. Nothing to optimize!" -f $SizeThreshold) -ForegroundColor Green
  return 
}

# Pre-filter: remove images that would be skipped during processing
# This ensures the batch always contains N images that truly need work
$candidates = $aboveThreshold | Where-Object {
  $webpPath = [IO.Path]::ChangeExtension($_.FullName, '.webp')
  # Keep if no WebP exists yet, or if -Force is set
  $Force -or -not (Test-Path $webpPath)
}

$skippedCount = $aboveThreshold.Count - @($candidates).Count
if ($skippedCount -gt 0) {
  Write-Host ("{0} images already have WebP and will be skipped (use -Force to re-process)." -f $skippedCount) -ForegroundColor Gray
}

if (-not $candidates) {
  Write-Host "All images above threshold already have WebP files. Nothing to optimize!" -ForegroundColor Green
  Write-Host "(Use -Force to re-process existing WebP files)" -ForegroundColor Gray
  return
}

# Apply batch limit (batch always contains images that need actual work)
$totalCandidates = @($candidates).Count
if ($BatchSize -gt 0 -and $totalCandidates -gt $BatchSize) {
  $candidates = $candidates | Select-Object -First $BatchSize
}

Write-Host ""
Write-Host "Image Optimization" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan
Write-Host ("Mode:        {0}" -f $(if ($ConvertOnly) { "Convert Only" } else { "Full Workflow" })) -ForegroundColor White
Write-Host ("Batch:       {0} of {1} images needing optimization (>{2} KB)" -f @($candidates).Count, $totalCandidates, $SizeThreshold) -ForegroundColor White
Write-Host ("Quality:     {0}" -f $Quality) -ForegroundColor White
Write-Host ("Max Size:    {0}px" -f $MaxDimension) -ForegroundColor White
Write-Host ("Min Savings: {0}% or {1} KB" -f $MinSavingsPercent, $MinSavingsKB) -ForegroundColor White

if ($DryRun) {
  Write-Host "[DRY RUN] No changes will be made." -ForegroundColor Yellow
}
Write-Host ""

# In page-bundle mode, markdown updates are scoped to the index.md in the same
# directory as the image, so we don't need to pre-load all markdown files.

# Track results
$results = @()
$processedCount = 0

foreach ($file in $candidates) {
  $sizeKB = [math]::Round($file.Length / 1KB, 1)
  $webpPath = [IO.Path]::ChangeExtension($file.FullName, '.webp')
  $webpName = Split-Path -Leaf $webpPath
  $relativePath = $file.FullName.Replace($Root, '').TrimStart('\', '/')
  
  $processedCount++
  Write-Host ("{0,6} KB  {1}" -f $sizeKB, $relativePath) -ForegroundColor Cyan
  
  if ($DryRun) {
    # For dry run, still create temp file to calculate savings
    $tmp = [IO.Path]::GetTempFileName() -replace '\.tmp$', '.webp'
    try {
      & $magick $file.FullName -strip -resize ("{0}x{0}>" -f $MaxDimension) -quality $Quality -define webp:method=6 $tmp 2>$null
      
      if (Test-Path $tmp) {
        $newBytes = (Get-Item $tmp).Length
        $savings = Get-SavingsInfo -OriginalBytes $file.Length -NewBytes $newBytes
        
        $action = if ($savings.MeetsThreshold) { 'WouldCreate' } else { 'NoBenefit' }
        $results += [pscustomobject]@{
          Source = $relativePath
          Action = $action
          OrigKB = $sizeKB
          NewKB = [math]::Round($newBytes / 1KB, 1)
          SavedKB = $savings.SavedKB
          Percent = $savings.Percent
          MdUpdates = 0
        }
        
        if ($savings.MeetsThreshold) {
          Write-Host ("  -> Would save {0} KB ({1}%)" -f $savings.SavedKB, $savings.Percent) -ForegroundColor Green
        } else {
          Write-Host ("  -> No benefit ({0}% savings below threshold)" -f $savings.Percent) -ForegroundColor Gray
        }
        
        Remove-Item $tmp -ErrorAction SilentlyContinue
      }
    } catch {
      Write-Host ("  -> Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
    continue
  }
  
  # Actual conversion
  try {
    & $magick $file.FullName -strip -resize ("{0}x{0}>" -f $MaxDimension) -quality $Quality -define webp:method=6 $webpPath 2>$null
    
    if (-not (Test-Path $webpPath)) {
      Write-Host "  x WebP creation failed" -ForegroundColor Red
      $results += [pscustomobject]@{
        Source = $relativePath
        Action = 'Failed'
        OrigKB = $sizeKB
        NewKB = $null
        SavedKB = 0
        Percent = 0
        MdUpdates = 0
      }
      continue
    }
    
    $newBytes = (Get-Item $webpPath).Length
    $savings = Get-SavingsInfo -OriginalBytes $file.Length -NewBytes $newBytes
    
    # Check if savings meet threshold
    if (-not $savings.MeetsThreshold) {
      Write-Host ("  x No benefit ({0}% / {1} KB below threshold) - removing WebP" -f $savings.Percent, $savings.SavedKB) -ForegroundColor Gray
      Remove-Item $webpPath -Force
      $results += [pscustomobject]@{
        Source = $relativePath
        Action = 'NoBenefit'
        OrigKB = $sizeKB
        NewKB = [math]::Round($newBytes / 1KB, 1)
        SavedKB = $savings.SavedKB
        Percent = $savings.Percent
        MdUpdates = 0
      }
      continue
    }
    
    Write-Host ("  + Created: {0} KB (saved {1} KB, {2}%)" -f ([math]::Round($newBytes / 1KB, 1)), $savings.SavedKB, $savings.Percent) -ForegroundColor Green
    
    $mdUpdates = 0
    
    # Full workflow: update markdown references in co-located index.md (page bundle)
    if (-not $ConvertOnly) {
      $originalName = $file.Name
      $pattern = [regex]::Escape($originalName)
      
      # Find index.md in the same directory as the image (page bundle pattern)
      $bundleMd = Join-Path $file.DirectoryName 'index.md'
      $mdFilesToCheck = @()
      if (Test-Path $bundleMd) {
        $mdFilesToCheck += Get-Item $bundleMd
      } else {
        # Fallback: check all .md files in the same directory
        $mdFilesToCheck = Get-ChildItem -Path $file.DirectoryName -Filter '*.md' -File -ErrorAction SilentlyContinue
      }
      
      foreach ($mdFile in $mdFilesToCheck) {
        $content = Get-Content -Path $mdFile.FullName -Raw -Encoding UTF8
        
        if ($content -imatch $pattern) {
          $newContent = $content -ireplace $pattern, $webpName
          
          if ($newContent -ne $content) {
            Set-Content -Path $mdFile.FullName -Value $newContent -Encoding UTF8 -NoNewline
            $mdUpdates++
          }
        }
      }
      
      if ($mdUpdates -gt 0) {
        Write-Host ("  + Updated: {0} markdown file(s)" -f $mdUpdates) -ForegroundColor Green
      }
      
      # Remove original (unless KeepOriginal)
      if (-not $KeepOriginal) {
        Remove-Item $file.FullName -Force
        Write-Host "  + Removed original" -ForegroundColor Green
      }
    }
    
    $results += [pscustomobject]@{
      Source = $relativePath
      Action = 'Created'
      OrigKB = $sizeKB
      NewKB = [math]::Round($newBytes / 1KB, 1)
      SavedKB = $savings.SavedKB
      Percent = $savings.Percent
      MdUpdates = $mdUpdates
    }
    
  } catch {
    Write-Host ("  x Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
    $results += [pscustomobject]@{
      Source = $relativePath
      Action = 'Failed'
      OrigKB = $sizeKB
      NewKB = $null
      SavedKB = 0
      Percent = 0
      MdUpdates = 0
    }
  }
}

# Summary
Write-Host ""
Write-Host ("=" * 50) -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

$created = $results | Where-Object Action -eq 'Created'
$wouldCreate = $results | Where-Object Action -eq 'WouldCreate'
$noBenefit = $results | Where-Object Action -eq 'NoBenefit'
$failed = $results | Where-Object Action -eq 'Failed'

$totalSavedKB = ($created | Measure-Object -Property SavedKB -Sum).Sum
$potentialKB = ($wouldCreate | Measure-Object -Property SavedKB -Sum).Sum
$totalMdUpdates = ($created | Measure-Object -Property MdUpdates -Sum).Sum

if ($DryRun) {
  Write-Host ("Would create:  {0} WebP files" -f $wouldCreate.Count) -ForegroundColor Green
  Write-Host ("Would save:    {0} KB" -f $potentialKB) -ForegroundColor Green
  Write-Host ("No benefit:    {0} files (below savings threshold)" -f $noBenefit.Count) -ForegroundColor Gray
  if ($skippedCount -gt 0) {
    Write-Host ("Pre-skipped:   {0} files (WebP exists, use -Force to re-process)" -f $skippedCount) -ForegroundColor Gray
  }
} else {
  Write-Host ("Created:       {0} WebP files" -f $created.Count) -ForegroundColor Green
  Write-Host ("Saved:         {0} KB total" -f $totalSavedKB) -ForegroundColor Green
  if (-not $ConvertOnly) {
    Write-Host ("MD updated:    {0} file(s)" -f $totalMdUpdates) -ForegroundColor Green
  }
  Write-Host ("No benefit:    {0} files" -f $noBenefit.Count) -ForegroundColor Gray
  Write-Host ("Failed:        {0} files" -f $failed.Count) -ForegroundColor $(if ($failed.Count -gt 0) { 'Red' } else { 'Gray' })
}

# Show detailed results table
if ($results.Count -gt 0) {
  Write-Host ""
  $results | Sort-Object Percent -Descending | 
    Select-Object Action, @{N='%';E={$_.Percent}}, SavedKB, OrigKB, NewKB, MdUpdates, Source | 
    Format-Table -AutoSize
}

# Next steps
if ($DryRun) {
  Write-Host "Run without -DryRun to apply changes." -ForegroundColor Yellow
} elseif ($BatchSize -gt 0 -and $totalCandidates -gt $BatchSize) {
  $remaining = $totalCandidates - $BatchSize
  Write-Host ("Batch complete. Run again to process remaining {0} images." -f $remaining) -ForegroundColor Cyan
}
