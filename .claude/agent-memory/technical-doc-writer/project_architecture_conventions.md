---
name: Architecture Section Conventions
description: Front matter schema, file location, weight numbering, and index update requirements for articles in the architecture section
type: project
---

Architecture articles live at `content/architecture/<slug>.md`.

**Why:** Consistent placement allows Hugo to resolve section URLs and apply the cascade type set in `_index.md`.

**How to apply:** Always save new architecture articles to this path and update `content/architecture/_index.md` to list the article under either "Architecture Styles" or "Architecture Patterns".

## Front Matter Schema

```yaml
---
title: <Full Title>
date: <YYYY-MM-DD>
description: <One- or two-sentence summary>
params:
  image: /architecture/images/<slug>.svg   # omit if no image exists yet
weight: <integer>
---
```

- `draft` is NOT included in existing articles (omit it).
- `params.image` is omitted when no image file exists.
- `weight` values seen so far: styles use 10–70 range; patterns start at 70+ (Web-Queue-Worker = 70, Competing Consumers = 80).

## Section Index

`content/architecture/_index.md` has two H2 lists:
- **Architecture Styles** — for style-level articles (Clean, EDA, Layered, etc.)
- **Architecture Patterns** — for pattern-level articles (Web-Queue-Worker, Competing Consumers, etc.)

Always add a bullet link to the appropriate list when creating a new article.

## Diagram Style

Mermaid `flowchart LR` is preferred for flow diagrams in this section (matches Web-Queue-Worker article). Add a short explanatory sentence immediately after each diagram.

## Section Labels for Bullet Lists

Lead bullet-list sections with a sentence in the form:
"These are some of the [benefits/tradeoffs/...] of [Pattern Name]:"
(matches existing article style in both web-queue-worker and event-driven articles)
