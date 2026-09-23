---
name: project_laws_conventions
description: Front matter schema, weight numbering, style variance, and markdownlint/hugo verification notes for content/laws/ articles.
metadata:
  type: project
---

`content/laws/*.md` articles document a "law" of software development (Conway's, Tesler's, Wirth's, etc.).

**Front matter schema** (YAML):
```yaml
---
title: "<Name>'s Law: <optional subtitle>"
date: YYYY-MM-DD
description: <1-2 sentence summary, used as meta description>
params:
  image: /laws/images/<slug>.png
weight: <number>
---
```

**Weight numbering**: mostly multiples of 10 assigned in rough alphabetical order (Amara's=10, Amdahl's=20, ... Wirth's=190), but there are already collisions (Tesler's and Kerckhoff's both 110) and gaps have been filled with non-multiples-of-10 when inserting a new law alphabetically between two existing ones without renumbering the whole set (e.g. McLuhan's Law=155, between Linus's Law=150 and Moore's Law=160). Check `grep -m1 "^weight:" content/laws/*.md | sort` before adding a new one.

**Style is NOT uniform** across existing articles — two sub-styles coexist:
1. Newer/rewritten style (teslers-law.md): opening italicized pull-quote with attribution, Table of Contents with anchor links matching `## Heading` slugs, `## References` section with numbered citations, relation-to-other-laws section linking sibling laws.
2. Older bulk-authored style (wirths-law.md, moores-law.md, etc.): inline hero image right after front matter (`![alt](./images/x.png)`), H1 restating the title, numbered subsections with bolded "Example:" callouts, `## Conclusion`, `## References`.

When the user references specific existing articles as the style to match (e.g. "match teslers-law.md and conways-law.md"), follow sub-style 1 for structure — but **always include the inline hero image regardless of sub-style**.

**Hero image is REQUIRED (decided 2026-09-23)**: `params.image` in front matter only feeds the `og:image` meta tag for social previews — it renders nothing on the page. Every `content/laws/` article must ALSO reference the image in the body, on its own line immediately after the front matter and before the first paragraph or pull-quote, using a content-relative path:

```markdown
![<name>'s law](./images/<slug>.png)
```

Note the two paths differ by design: front matter uses the absolute `/laws/images/<slug>.png`, the body uses the relative `./images/<slug>.png`. Some older articles (teslers-law.md, linus-law.md, galls-law.md, etc.) predate this decision and have front matter only — do not copy that omission. This is documented in README.md under "Displaying the Featured Image".

**`_index.md` alphabetical list**: `content/laws/_index.md` has a flat alphabetical bullet list `- [Name's Law](path/)` under "## Alphabetical List of Software Development Laws". Add new entries in strict alphabetical order by the displayed name. Some list entries point to `content/principles/` or `content/antipatterns/` pages, or external URLs, when the "law" isn't itself a `content/laws/` article — don't assume every list entry maps to a file in `content/laws/`.

**Verification workflow that works in this repo**:
- `markdownlint content/laws/<file>.md` is available globally (found at the npm global bin, no repo-local `.markdownlintrc`/config exists). Default rules apply — including MD013 line-length at 80 chars. Nearly every existing law article (teslers-law.md, conways-law.md, wirths-law.md, etc.) fails MD013 pervasively because prose lines are unwrapped — this is pre-existing and accepted across the whole `content/laws/` directory, so don't treat MD013 failures on prose paragraphs as something to fix; only fix rule violations that are NOT already present in the reference articles you were told to match (e.g. MD036 "emphasis used instead of heading" — triggered when an opening italicized pull-quote line has no trailing attribution text; fix by appending `— Attribution` to the line, same as teslers-law.md does).
- `hugo build` in this repo currently emits several global deprecation WARN lines unrelated to any specific page (`languageCode` deprecated, `.Language.LanguageDirection`, `.Site.Data`, `.Site.LanguageCode`) — these appear on every build regardless of changes and are not something a new content page needs to fix.
- To confirm a new page actually rendered: check `public/<section>/<slug>/index.html` exists after `hugo build` and grep its `<title>` tag.

See also [[project_architecture_conventions]] for the sibling `content/architecture/` conventions (different section, different schema).
