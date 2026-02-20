<#
.SYNOPSIS
  Creates the Hugo content/docs directory structure and section _index.md files.
.DESCRIPTION
  Sets up the skeleton content/docs/{category}/_index.md files required by Hugo and
  Hextra before content migration begins (Phase 1.1 and 1.2 of the migration plan).
  Safe to re-run - will not overwrite existing _index.md files unless -Overwrite is used.
.PARAMETER DryRun
  Show what would be created without writing any files.
.PARAMETER Overwrite
  Recreate _index.md files even if they already exist.
.EXAMPLE
  ./setup-structure.ps1 -DryRun
  ./setup-structure.ps1
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Overwrite
)

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..") | Select-Object -ExpandProperty Path
$docsRoot = Join-Path $repoRoot "content\docs"

# Category metadata: title, description, weight (sidebar order)
$categories = @(
    @{ Slug="design-patterns";      Title="Design Patterns";         Description="Common software design patterns for solving recurring problems.";                      Weight=10  }
    @{ Slug="principles";           Title="Principles";              Description="Core software development principles including SOLID, DRY, YAGNI, and more.";           Weight=20  }
    @{ Slug="practices";            Title="Practices";               Description="Software development practices that improve quality, maintainability, and teamwork.";    Weight=30  }
    @{ Slug="antipatterns";         Title="Antipatterns";            Description="Common antipatterns to recognize and avoid in software design and development.";         Weight=40  }
    @{ Slug="domain-driven-design"; Title="Domain-Driven Design";    Description="Strategic and tactical DDD patterns for building complex domain models.";               Weight=50  }
    @{ Slug="laws";                 Title="Laws";                    Description="Well-known laws and observations about software development.";                           Weight=60  }
    @{ Slug="testing";              Title="Testing";                 Description="Software testing strategies, patterns, and best practices.";                             Weight=70  }
    @{ Slug="architecture";         Title="Architecture";            Description="Software architecture patterns and styles.";                                             Weight=80  }
    @{ Slug="values";               Title="Values";                  Description="Core values that guide effective software development teams.";                           Weight=90  }
    @{ Slug="terms";                Title="Terms";                   Description="Common software development terms and definitions.";                                     Weight=100 }
    @{ Slug="tools";                Title="Tools";                   Description="Tools and practices that support software development workflows.";                       Weight=110 }
    @{ Slug="code-smells";          Title="Code Smells";             Description="Code smells to watch for as indicators of deeper design problems.";                     Weight=120 }
)

$created  = 0
$skipped  = 0

foreach ($cat in $categories) {
    $catDir    = Join-Path $docsRoot $cat.Slug
    $indexFile = Join-Path $catDir "_index.md"
    $imagesDir = Join-Path $catDir "images"

    $content = @"
---
title: "$($cat.Title)"
description: "$($cat.Description)"
weight: $($cat.Weight)
---
"@

    if (Test-Path $indexFile) {
        if (-not $Overwrite) {
            Write-Host "[SKIP] $($cat.Slug)/_index.md (already exists)" -ForegroundColor DarkYellow
            $skipped++
            continue
        }
    }

    if ($DryRun) {
        Write-Host "[WOULD CREATE] $($cat.Slug)/_index.md" -ForegroundColor Magenta
        $created++
        continue
    }

    # Create directories
    if (-not (Test-Path $catDir))    { New-Item -ItemType Directory -Path $catDir    -Force | Out-Null }
    if (-not (Test-Path $imagesDir)) { New-Item -ItemType Directory -Path $imagesDir -Force | Out-Null }

    [System.IO.File]::WriteAllText($indexFile, $content, [System.Text.Encoding]::UTF8)
    Write-Host "[OK] $($cat.Slug)/_index.md" -ForegroundColor Green
    $created++
}

Write-Host "`nDone. Created: $created  Skipped: $skipped" -ForegroundColor Cyan
if ($DryRun) { Write-Host "Dry run - no files written." -ForegroundColor Yellow }
