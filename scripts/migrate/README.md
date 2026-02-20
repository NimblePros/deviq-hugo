# Migration Scripts

These scripts automate the Gatsby-to-Hugo content migration described in `.agents/plans/gatsby-to-hugo-migration.md`. They are intended for one-time use during the migration and are not needed for ongoing site maintenance.

All scripts must be run from the **repo root** or from within `scripts/migrate/` — they resolve paths relative to the repo root automatically.

---

## Scripts

### `setup-structure.ps1`

**Phase 1** — Creates the `content/docs/{category}/` directories and `_index.md` section index files required by Hugo and the Hextra theme before any content is migrated.

```powershell
# Preview what would be created
./scripts/migrate/setup-structure.ps1 -DryRun

# Create all section directories and _index.md files
./scripts/migrate/setup-structure.ps1
```

Run this **first**, before any other migration script.

---

### `migrate-content.ps1`

**Phase 2–5** — Main migration script. Reads source markdown from `_reference/src/docs/{category}/`, transforms frontmatter and internal links to Hugo/Hextra format, and writes to `content/docs/{category}/`.

**Frontmatter transformations:**
- Removes quotes from `date` values
- Converts `featuredImage: "./images/foo.png"` → `params.image: /docs/{category}/images/foo.png`
- Converts internal links: `/category/slug` → `/docs/category/slug/`

```powershell
# Preview migration for one category
./scripts/migrate/migrate-content.ps1 -Category design-patterns -DryRun

# Migrate a category including its images
./scripts/migrate/migrate-content.ps1 -Category design-patterns -IncludeImages

# Migrate all categories
./scripts/migrate/migrate-content.ps1 -IncludeImages

# Migrate in batches of 25 files
./scripts/migrate/migrate-content.ps1 -Limit 25

# Re-process already-migrated files
./scripts/migrate/migrate-content.ps1 -Category principles -Overwrite
```

**Parameters:**

| Parameter | Description |
|---|---|
| `-Category` | Limit to a specific category (e.g. `design-patterns`). Omit to process all. |
| `-Limit N` | Stop after N files across all categories (for incremental runs). |
| `-DryRun` | Preview changes without writing files. |
| `-Overwrite` | Reprocess files that already exist at the destination. |
| `-IncludeImages` | Also copy `images/` subdirectory contents. |

---

### `migrate-images.ps1`

**Phase 3–5** — Copies images from `_reference/src/docs/{category}/images/` to `content/docs/{category}/images/`. Also reports any markdown image references that point to missing files.

```powershell
# Preview what would be copied
./scripts/migrate/migrate-images.ps1 -DryRun

# Copy images for all categories
./scripts/migrate/migrate-images.ps1

# Copy images for a single category
./scripts/migrate/migrate-images.ps1 -Category principles

# Overwrite existing destination images
./scripts/migrate/migrate-images.ps1 -Overwrite
```

> Note: `migrate-content.ps1 -IncludeImages` also copies images inline. Use this script separately if you want to migrate images without re-processing markdown content.

---

### `convert-frontmatter.ps1`

**Utility** — Re-processes frontmatter in already-migrated `content/docs/` files. Useful for bulk corrections without re-copying body content.

```powershell
# Preview changes across all docs
./scripts/migrate/convert-frontmatter.ps1 -DryRun

# Apply to a specific category directory
./scripts/migrate/convert-frontmatter.ps1 -Path content/docs/principles

# Add weight ordering (alphabetical, step 10)
./scripts/migrate/convert-frontmatter.ps1 -AddWeight

# Drop featuredImage fields entirely
./scripts/migrate/convert-frontmatter.ps1 -RemoveFeaturedImage
```

---

### `validate-links.ps1`

**Phase 6** — Validates internal links in `content/docs/` after migration. Checks that `/docs/{category}/{slug}` paths resolve to actual files. Reports broken links, unconverted Gatsby-style links, and (optionally) broken image references.

```powershell
# Check all links in content/docs
./scripts/migrate/validate-links.ps1

# Check links and image references
./scripts/migrate/validate-links.ps1 -CheckImages

# Find only unconverted Gatsby-style links (missing /docs/ prefix)
./scripts/migrate/validate-links.ps1 -GatsbyLinksOnly

# Check a specific category
./scripts/migrate/validate-links.ps1 -Path content/docs/design-patterns
```

Exit code is `1` if broken links or images are found, `0` if all pass.

---

## Recommended Workflow

Follow the migration phases from `.agents/plans/gatsby-to-hugo-migration.md`:

```powershell
# Phase 1: Set up directory structure
./scripts/migrate/setup-structure.ps1 -DryRun
./scripts/migrate/setup-structure.ps1

# Verify Hugo builds with empty sections
hugo server -D

# Phase 2-5: Migrate content (start with high-priority categories)
./scripts/migrate/migrate-content.ps1 -Category design-patterns -IncludeImages -DryRun
./scripts/migrate/migrate-content.ps1 -Category design-patterns -IncludeImages

./scripts/migrate/migrate-content.ps1 -Category principles -IncludeImages
./scripts/migrate/migrate-content.ps1 -Category practices -IncludeImages
./scripts/migrate/migrate-content.ps1 -Category antipatterns -IncludeImages

# Continue with medium and low priority categories...
./scripts/migrate/migrate-content.ps1 -IncludeImages  # migrate all remaining

# Phase 6: Validate
./scripts/migrate/validate-links.ps1 -CheckImages
hugo build

# Fix any remaining broken links or frontmatter issues
./scripts/migrate/convert-frontmatter.ps1 -DryRun
```

---

## Source and Destination

| | Path |
|---|---|
| **Source** | `_reference/src/docs/{category}/` |
| **Destination** | `content/docs/{category}/` |
| **Images source** | `_reference/src/docs/{category}/images/` |
| **Images dest** | `content/docs/{category}/images/` |

The `_reference/` directory is kept intact throughout migration as a read-only reference.
