# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
hugo server -D          # Start dev server with drafts
hugo build              # Build the site for production
hugo new content/<path> # Create new content file
markdownlint content/   # Lint markdown files
```

## Self-Correction Workflow

This project uses strict Hugo and various testing tools a feedback loop for AI-generated code:

1. **Write code** → 2. **Run checks** → 3. **Read errors** → 4. **Fix issues** → 5. **Repeat until clean**

### After writing or modifying code, always run:

```bash
hugo server -D    # Start server with Drafts
```

### Why this matters for AI development:

- **Most errors are precise**: `Type 'string | undefined' is not assignable to type 'string'` tells you exactly what's wrong
- **Catches bugs before runtime**: No need to run the app to find issues
- **Strict settings catch real bugs**:
  - Warnings about missing files or content prevent broken pages at runtime

### Reading error output

Errors typicall include file path, line, and column: `src/app/page.tsx:15:3`

- Navigate directly to the problem
- The error message describes what's wrong
- Fix and re-run until all checks pass

## Testing

Tests are executable specifications and provide precise feedback for AI-generated code.

**Run tests after implementing features:**

```bash
# test script goes here
```

**Why tests matter for AI development:**

- Test failures tell you exactly what's broken: test name, file:line, expected vs actual
- Tests define "done"—write them first when possible
- Fast execution (~10x faster than Jest) enables frequent runs
- Coverage reports (80% threshold) show gaps

**Test file conventions:**

TBD

**Self-correction with tests:**

1. Write test defining expected behavior
2. Implement the feature
3. Run tests
4. If test fails, read the diff (expected vs actual)
5. Fix and re-run until green

## Tech Stack

- Hugo 0.156.0

## Local Tools

- Hugo should be installed globally; if not install it using `choco upgrade hugo-extended`

## Code Style

- 2-space indentation, 100 char line width, double quotes
- Use common conventions appropriate to the language
- For Markdown, use `markdownlint` to verify correctness

## Multi-Agent Setup

This project uses Claude Code's multi-agent support. Available agents are in `.claude/agents/`.

### Available Agents

| Agent | Description |
|---|---|
| `gatsby-to-hugo-migrator` | Specialized for migrating content, converting frontmatter, creating shortcodes, mapping Gatsby plugins to Hugo equivalents, and adapting scripts from `scripts/reference/` |

### Invoking an Agent

Ask Claude to use a specific agent by name:

> "Use the gatsby-to-hugo-migrator to analyze what content is in `_reference/src/docs` and plan the migration"

Or Claude will automatically select the appropriate agent based on the task context.
