# Gatsby to Hugo Migration Plan

This document outlines the phased approach for migrating content from the Gatsby site (`_reference/`) to the Hugo site.

## Migration Overview

| Metric | Count |
|--------|-------|
| Total Markdown Files | 186 |
| Total Images | 225 |
| Content Categories | 12 |
| Theme | Hextra |

### Content Categories to Migrate

| Category | Description | Priority |
|----------|-------------|----------|
| design-patterns | 25 patterns including Repository, Strategy, Decorator, etc. | High |
| principles | 24 principles including SOLID, DRY, YAGNI, etc. | High |
| practices | 34 development practices | High |
| antipatterns | 40 antipatterns | High |
| domain-driven-design | 18 DDD concepts | Medium |
| laws | 21 software laws | Medium |
| testing | 9 testing topics | Medium |
| architecture | 4 architecture patterns | Medium |
| values | 7 XP values | Low |
| terms | 4 general terms | Low |
| tools | 3 tool topics | Low |
| code-smells | 2 code smell topics | Low |

---

## Phase 1: Foundation & Infrastructure (Days 1-2)

### 1.1 Create Hugo Content Structure

Create the directory structure mirroring Gatsby categories:

```
content/docs/
├── _index.md (already exists)
├── antipatterns/
│   ├── _index.md
│   └── images/
├── architecture/
│   ├── _index.md
│   └── images/
├── code-smells/
│   ├── _index.md
│   └── images/
├── design-patterns/
│   ├── _index.md
│   └── images/
├── domain-driven-design/
│   ├── _index.md
│   └── images/
├── laws/
│   ├── _index.md
│   └── images/
├── practices/
│   ├── _index.md
│   └── images/
├── principles/
│   ├── _index.md
│   └── images/
├── terms/
│   ├── _index.md
│   └── images/
├── testing/
│   ├── _index.md
│   └── images/
├── tools/
│   ├── _index.md
│   └── images/
└── values/
    ├── _index.md
    └── images/
```

### 1.2 Create Section Index Files

Each `_index.md` should include:

```yaml
---
title: "Design Patterns"
description: "Software design patterns for solving common problems"
weight: 10
---
```

### 1.3 Configure Hugo Menu/Navigation

Update `hugo.toml` to include documentation sections in the sidebar:

```toml
[params.docs]
  sidebar = true
```

### 1.4 Create Migration Scripts

Create PowerShell scripts in `scripts/`:

1. `migrate-content.ps1` - Main content migration script
2. `convert-frontmatter.ps1` - Frontmatter conversion utility
3. `migrate-images.ps1` - Image migration utility
4. `validate-links.ps1` - Internal link validation

### Deliverables
- [ ] All section directories created
- [ ] All `_index.md` files created with proper frontmatter
- [ ] Migration scripts ready for use
- [ ] Hugo site builds successfully with empty sections

---

## Phase 2: Frontmatter & Content Transformation (Days 3-4)

### 2.1 Frontmatter Mapping

**Gatsby Format:**
```yaml
---
title: "Repository Pattern"
date: "2024-08-19"
description: "Description text..."
featuredImage: "./images/repository-pattern.png"
---
```

**Hugo/Hextra Format:**
```yaml
---
title: "Repository Pattern"
date: 2024-08-19
description: "Description text..."
weight: 10
params:
  image: /docs/design-patterns/images/repository-pattern.png
---
```

### 2.2 Transformation Rules

| Gatsby | Hugo | Notes |
|--------|------|-------|
| `title` | `title` | Keep as-is |
| `date` | `date` | Remove quotes |
| `description` | `description` | Keep as-is |
| `featuredImage` | Remove or convert | Hextra handles images differently |
| (none) | `weight` | Add for ordering |

### 2.3 Link Transformations

Convert internal links:

| Gatsby Link | Hugo Link |
|-------------|-----------|
| `/principles/dependency-inversion-principle` | `/docs/principles/dependency-inversion-principle/` |
| `/design-patterns/strategy-pattern` | `/docs/design-patterns/strategy-pattern/` |

### 2.4 Image Reference Transformations

Convert image references:

| Gatsby | Hugo |
|--------|------|
| `![alt](images/example.png)` | `![alt](images/example.png)` (relative, same) |
| `./images/example.png` in frontmatter | Handled via page bundles or static |

### Deliverables
- [ ] Frontmatter conversion script tested
- [ ] Link transformation regex patterns defined
- [ ] Sample content migrated and validated

---

## Phase 3: High-Priority Content Migration (Days 5-8)

### 3.1 Design Patterns (25 files)

Order of migration:
1. `design-patterns-overview.md` (index)
2. Core GoF patterns: Strategy, Repository, Decorator, Factory, Singleton
3. Structural patterns: Adapter, Facade, Proxy
4. Behavioral patterns: Observer, Mediator, Chain of Responsibility
5. Domain patterns: CQRS, Domain Events, Specification
6. Remaining patterns

### 3.2 Principles (24 files)

Order of migration:
1. `principles-overview.md` (index)
2. SOLID principles (5 files)
3. DRY, YAGNI, KISS
4. Remaining principles alphabetically

### 3.3 Practices (34 files)

Order of migration:
1. `practices-overview.md` (index)
2. Core practices: TDD, Refactoring, Dependency Injection, CI
3. Code quality practices
4. Team practices
5. Remaining practices

### 3.4 Antipatterns (40 files)

Order of migration:
1. `antipatterns-overview.md` (index)
2. Common antipatterns: Big Ball of Mud, Spaghetti Code, Golden Hammer
3. Process antipatterns
4. Design antipatterns
5. Remaining antipatterns

### Deliverables
- [ ] 123 high-priority files migrated
- [ ] All associated images copied
- [ ] Internal links validated
- [ ] Hugo builds without errors

---

## Phase 4: Medium-Priority Content Migration (Days 9-11)

### 4.1 Domain-Driven Design (18 files)

1. `ddd-overview.md` (index)
2. Strategic patterns: Bounded Context, Context Mapping, Subdomain
3. Tactical patterns: Entity, Value Object, Aggregate
4. Supporting concepts

### 4.2 Laws (21 files)

1. `laws-overview.md` (index)
2. Popular laws: Conway's, Murphy's, Brooks's
3. Remaining laws alphabetically

### 4.3 Testing (9 files)

1. `testing-overview.md` (index)
2. Test types: Unit, Integration, Functional
3. Testing practices

### 4.4 Architecture (4 files)

1. `architecture-overview.md` (index)
2. Clean Architecture, Vertical Slice, Event-Driven

### Deliverables
- [ ] 52 medium-priority files migrated
- [ ] All associated images copied
- [ ] Internal links validated

---

## Phase 5: Low-Priority Content Migration (Day 12)

### 5.1 Values (7 files)

1. `values-overview.md` (index)
2. XP Values: Communication, Courage, Feedback, Respect, Simplicity

### 5.2 Terms (4 files)

1. `terms-overview.md` (index)
2. Technical Debt, Bus Factor, Kinds of Models

### 5.3 Tools (3 files)

1. `tools-overview.md` (index)
2. Version Control, Build Server

### 5.4 Code Smells (2 files)

1. `code-smells-overview.md` (index)
2. Primitive Obsession

### Deliverables
- [ ] 16 low-priority files migrated
- [ ] All associated images copied
- [ ] Internal links validated

---

## Phase 6: Validation & Quality Assurance (Days 13-14)

### 6.1 Link Validation

```bash
# Check for broken internal links
hugo --printUnusedTemplates
```

Run custom link checker script to verify:
- All internal `/docs/` links resolve
- No orphaned images
- No broken external links (optional)

### 6.2 Content Verification

For each section:
- [ ] All files present
- [ ] Frontmatter valid (run `hugo server -D`)
- [ ] Images render correctly
- [ ] Code blocks syntax highlighted
- [ ] Tables render properly

### 6.3 Visual QA

- [ ] Navigation sidebar shows all sections
- [ ] Section pages list child pages correctly
- [ ] Search indexes all content
- [ ] Mobile responsive layout works

### 6.4 Build Validation

```bash
hugo build
hugo server -D
```

Fix any errors or warnings.

### Deliverables
- [ ] All links validated
- [ ] All content renders correctly
- [ ] No build errors or warnings
- [ ] Search working

---

## Phase 7: Cleanup & Documentation (Day 15)

### 7.1 Remove Reference Content

Once migration is verified:
- Archive `_reference/` directory (or keep for reference)
- Remove from git tracking if desired

### 7.2 Update Documentation

Update `README.md` with:
- Content structure documentation
- How to add new content
- Frontmatter reference

### 7.3 Update CLAUDE.md

Add migration completion notes and any learned patterns.

### 7.4 Create Content Templates

Create archetypes for each content type:

```
archetypes/
├── design-pattern.md
├── principle.md
├── practice.md
├── antipattern.md
└── default.md
```

### Deliverables
- [ ] Reference content archived
- [ ] Documentation updated
- [ ] Archetypes created
- [ ] Migration complete

---

## Migration Script Requirements

### Main Migration Script (`scripts/migrate-gatsby-content.ps1`)

```powershell
param(
    [string]$Category,        # e.g., "design-patterns"
    [switch]$DryRun,          # Preview changes without applying
    [switch]$IncludeImages    # Also copy images
)
```

**Functionality:**
1. Read source markdown from `_reference/src/docs/{category}/`
2. Transform frontmatter (YAML parsing)
3. Transform internal links (regex replacement)
4. Copy to `content/docs/{category}/`
5. Copy images if `-IncludeImages` specified

### Frontmatter Transformation Rules

```powershell
# Remove quotes from date
$date = $date -replace '"', ''

# Remove featuredImage (not used in Hextra)
# Or convert to params.image if needed

# Add weight based on alphabetical order or manual override
```

### Link Transformation Rules

```powershell
# Pattern: [text](/category/slug)
# Replace: [text](/docs/category/slug/)

$content = $content -replace '\]\(/([\w-]+)/([\w-]+)\)', '](/docs/$1/$2/)'
```

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Broken internal links | Run link validation script after each phase |
| Missing images | Verify image count matches source |
| Malformed frontmatter | Validate YAML before committing |
| Lost content | Keep `_reference/` until migration verified |
| Theme incompatibilities | Test each content type early in Phase 2 |

---

## Success Criteria

1. **Completeness**: All 186 markdown files migrated
2. **Image Parity**: All 225 images accessible and rendering
3. **Link Integrity**: Zero broken internal links
4. **Build Success**: `hugo build` completes without errors
5. **Visual Quality**: Content renders as expected in browser
6. **Search Functionality**: All content indexed and searchable
7. **Navigation**: All sections accessible via sidebar

---

## Estimated Timeline

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 1: Foundation | 2 days | Day 2 |
| Phase 2: Transformation | 2 days | Day 4 |
| Phase 3: High-Priority | 4 days | Day 8 |
| Phase 4: Medium-Priority | 3 days | Day 11 |
| Phase 5: Low-Priority | 1 day | Day 12 |
| Phase 6: Validation | 2 days | Day 14 |
| Phase 7: Cleanup | 1 day | Day 15 |

**Total: ~15 working days**

---

## Quick Reference: File Counts by Category

| Category | Files | Images (approx) |
|----------|-------|-----------------|
| antipatterns | 40 | 31 |
| design-patterns | 25 | varies |
| practices | 34 | varies |
| principles | 24 | varies |
| domain-driven-design | 18 | varies |
| laws | 21 | varies |
| testing | 9 | varies |
| values | 7 | varies |
| architecture | 4 | varies |
| terms | 4 | varies |
| tools | 3 | varies |
| code-smells | 2 | varies |
| **Total** | **186** | **225** |
