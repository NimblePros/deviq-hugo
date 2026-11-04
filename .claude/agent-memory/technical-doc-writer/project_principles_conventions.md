---
name: project_principles_conventions
description: Front matter, weights, index layout, prose style, and markdownlint gotchas for content/principles/ articles.
metadata:
  type: project
---

`content/principles/*.md` documents named design principles (DRY, KISS, YAGNI, SOLID members, Lean principles, etc.).

**Style varies by age.** Older articles (dont-repeat-yourself.md, keep-it-simple.md, yagni.md, once-and-only-once.md, fail-fast.md) are short: hero image, a few prose paragraphs, optional `## Quotes`, `## See Also`, `## References` (references are one link per paragraph, not bullets). Newer articles (make-illegal-states-unrepresentable.md, progressive-disclosure.md) are longer with H2/H3 sections, C# examples, and tables. For a new article, the newer shape plus `## See Also` and `## References` fits well.

**Hero image**: as of 2026-11-03 most principles articles show the image in the body (PR #97 retrofitted 11). Include both `params.image: /principles/images/<slug>.png` and `![alt](./images/<slug>.png)` as the first body line. `verify_images.py principles` has a pre-existing failure for stable-dependencies (jpg vs png) and 2 articles without an image — not yours to fix.

**Weights**: roughly alphabetical, multiples of 10 with gap-fill values (amplify-learning=5, build-in-quality=25, optimize-the-whole=155, fairbairn-threshold=75). `_index.md` itself has weight 20.

**`_index.md`**: CRLF. One alphabetical `## Principles` bullet list using short display names (e.g. "Hollywood", "Dependency Inversion", "Least Astonishment, Principle of"), plus a separate `### Lean Software Development` list in NON-alphabetical (book) order. Not every article is listed (fail-fast.md is absent from the index).

**Line endings**: git `core.autocrlf=true`, so the repo stores LF and the working tree gets CRLF — Git Bash `sed -i` silently rewrote a CRLF file to LF; use a bytes-mode Python edit or the Edit tool instead.

**markdownlint gotcha**: a heading ending in `C#` (e.g. `## An Example in C#`) triggers MD020 (it parses as a closed ATX heading). Put `C#` mid-heading (`## A C# Example`, anchor `#a-c-example`).
