# DevIQ.com - a Hugo site

[DevIQ.com](https://DevIQ.com/)

[Previous Gatsby Repo](https://github.com/ardalis/deviq-gatsby)

**Before opening a pull request, be sure to read [this Pull Request Etiquette blog post](https://blog.nimblepros.com/blogs/pull-request-etiquette/).**

## Prerequisites

- [Hugo extended](https://gohugo.io/installation/) installed globally.
- On Windows (Chocolatey):

```powershell
choco upgrade hugo-extended
```

## Build and Run Locally

From the repository root:

1. Start the local dev server (includes draft content):

```bash
hugo server -D
```

1. Open the local site (default): `http://localhost:1313/`
2. Build a production version:

```bash
hugo build
```

1. Optional: lint markdown content files:

```bash
markdownlint content/
```

## Add a New Article

Run `./scripts/create-article.ps1`.

Or:

1. Choose the correct section folder under `content/` (for example: `antipatterns`, `principles`, `practices`, `testing`).
2. Create a new page using a kebab-case slug:

```bash
hugo new content/<section>/<slug>.md
```

Example:

```bash
hugo new content/principles/example-principle.md
```

1. Update frontmatter. Most pages include at least:

```yaml
---
title: Example Principle
date: 2026-03-14
description: One or two concise sentences summarizing the article.
params:
 image: /principles/images/example-principle.png
weight: 10
---
```

1. Add the article body content, links, and references.
2. Run `hugo server -D` and verify the page renders and appears in the expected section.
3. When the article is ready to publish, ensure `draft` is removed or set to `false`.

### Creating a Featured Image

We are experimenting with ImgForge, a tool Ardalis built:

The following script will run the latest version using a random background image from Unsplash. Run it multiple times if you don't like the image, or replace `random` with the image filename you'd like to use.

The template HTML file (which adds the DevIQ watermark) is in `.imgforge/template.html`.

```bash
dnx -y imgforge -- generate --title "Test Title" --bg random --template .imgforge --format blog
```

We have a process for creating a featured image using Canva:

1. The DevIQ template is [read-only on Canva](https://www.canva.com/design/DAGTShSdi3E/tMJgAOTI5eXEZ2-2qvTyDQ/edit). Make a copy of the file in Canva by going to **File** > **Make a copy**.
2. Update the title.
3. Find an appropriate background by going to **Elements** > **Photos** and search.
4. Drag the photo to the canvas, towards the middle of the image.
5. Right-click on the image and select **Replace background**.
6. Download the image and save it in the respective `images` folder.
7. Update the frontmatter for the new page with the correct file name.
