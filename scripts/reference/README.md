# Reference Scripts

The scripts in this folder come from other sites that have previously been upgraded from Gatsby to Hugo. Some are meant to be in the repo root to assist with building, testing, or starting the site. Others are meant to be useful only during the migration from the old Gatsby site to the new Hugo site. And some are meant to be used on an ongoing basis.

Some may be ready to use as-is; others likely will require some edits to work in this repo.

## Move to Root

Scripts for running, building, starting, and adding new content should be in the root.

- build.ps1 (requires edits) - Builds Hugo site with npm dependencies, Tailwind CSS, and Pagefind search indexing. References "NimblePros Hugo blog".
- build.sh (requires edits) - Bash version of build.ps1 for Linux/Mac. References "NimblePros Hugo blog".
- start.ps1 (requires edits) - Interactive menu to start dev server, build, or create new posts. References "Ardalis Hugo Blog".
- start-hugo.bat (requires edits) - Windows batch file to build and start Cloudflare Pages dev server. Has hardcoded Hugo path.
- new-blog-post.ps1 (as is) - Interactive script to create new blog posts using Hugo archetypes.

## Move to Scripts/Migrate

Scripts that will only be useful during the migration from Gatsby to Hugo should go in /scripts/migrate

- migrate-gatsby-blog.ps1 (requires edits) - Comprehensive Gatsby-to-Hugo migration with frontmatter conversion and featured image generation. References ardalis-specific paths and logo.
- migrate-posts.ps1 (requires edits) - Simple post migration from Gatsby content/blog to Hugo content/posts. References nimblepros-blog-gatsby folder.
- migrate-images-to-assets.ps1 (requires edits) - Copies images from static/img to assets/img for Hugo image processing. References site-specific hero images.

## Move to Scripts

Scripts that may be useful on an ongoing basis should be moved to /scripts

### Image Tools

- image-audit.ps1 (as is) - Audits images for size, dimensions, and optimization opportunities. Uses ImageMagick.
- optimize-image.ps1 (as is) - Adds and optimizes a single image for blog posts, copies to assets/img and static/img.
- optimize-images.ps1 (requires edits) - Batch converts images to WebP, updates markdown references. Default root is content/posts.
- optimize-images.sh (requires edits) - Bash version of optimize-images.ps1. Default root is content/posts.

### Validation Tools

- check-links.ps1 (requires edits) - Runs lychee link checker against built site. References ardalis.com.
- validate-frontmatter.ps1 (as is) - Validates required frontmatter fields (title, date, description, featuredImage) in blog posts.
- list-drafts.ps1 (requires edits) - Lists all draft posts. Hardcoded to content/blog path.

### Testing Tools (CSS/Visual/Performance)

- test-setup.ps1 (as is) - Installs testing tools (BackstopJS, stylelint, pa11y, lighthouse) and creates config files.
- test-all.ps1 (as is) - Runs complete test suite: CSS validation, visual regression, accessibility, and performance.
- test-baseline.ps1 (as is) - Captures reference screenshots for visual regression testing using BackstopJS.
- test-visual-regression.ps1 (as is) - Compares current screenshots against baseline to detect visual changes.
- test-css-validation.ps1 (requires edits) - Validates CSS syntax using stylelint. Hardcoded to static/css/*.css.
- test-accessibility.ps1 (requires edits) - Tests pages for WCAG accessibility using pa11y. Default URLs include /books/ which may not exist.
- test-performance.ps1 (as is) - Runs Lighthouse audits to measure performance, accessibility, best practices, and SEO.
- automated-testing.ps1 (requires edits) - Comprehensive automated testing for Open Graph, links, etc. References ardalis.com.

### BlueSky Integration Testing (Site-Specific)

- test-bluesky-browser.ps1 (requires edits) - Cross-browser testing for BlueSky social interactions feature. Site-specific functionality.
- test-bluesky-performance.ps1 (requires edits) - Performance testing for BlueSky interactions JavaScript. Site-specific functionality.
