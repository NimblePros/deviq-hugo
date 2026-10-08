# Issue #88 — Update to use latest version of ImgForge 0.2.0

- **Issue:** [NimblePros/deviq-hugo#88](https://github.com/NimblePros/deviq-hugo/issues/88)
- **Branch:** `t3code/implement-issue-88-feature`
- **Date:** 2026-10-08

## Goal

Move the ImgForge template configuration from the legacy `.imgforge/` folder to the
`.tools/imgforge/` location introduced in [ImgForge v0.2.0](https://github.com/ardalis/ImgForge/releases/tag/v0.2.0),
and update every doc/skill/agent file that tells a human or an agent how to generate a
featured image.

## Context gathered

- Issue body (no comments, no attachments, no linked issues): *"Move imgforge configuration
  to new `.tools/` location and update all docs, skills, etc. that reference how to use
  ImgForge for image creation."*
- ImgForge v0.2.0 release notes + README confirm the new behavior:
  - When `--template` is omitted, ImgForge looks for `.tools/imgforge/template.html` first,
    then the legacy `.imgforge/template.html` (which still works but prints a tip).
  - If no default template is found in the current directory and the cwd is inside a git
    repository, ImgForge walks parent directories up to the repository root (nearest folder
    containing `.git`), so it can be run from any subfolder.
  - Within one directory, `.tools/imgforge/template.html` wins over `.imgforge/template.html`.
  - Follows the [tools-dir spec](https://github.com/tools-dir/spec).
- Current repo state:
  - `.imgforge/template.html` — DevIQ-branded Scriban template; references the watermark as
    a **relative** path (`src="deviq-icon-300x300.png"`), so the icon must move with it.
  - `.imgforge/deviq-icon-300x300.png` — watermark asset.
  - Only two files mention ImgForge: `README.md` and `.claude/skills/deviq-article/SKILL.md`.
    Both pass `--template .imgforge` explicitly.
- `origin/ardalis/imgforge` exists but is identical to `main` — no prior work to build on.

## Assumptions

1. Docs will keep passing `--template .tools/imgforge` **explicitly** rather than relying on
   implicit discovery. Explicit is unambiguous, works from any cwd, and is immune to the
   `.git`-is-a-file case in git worktrees (this repo is frequently worked in worktrees).
   The implicit-discovery behavior is mentioned in docs as a convenience.
2. The legacy `.imgforge/` folder is **deleted**, not kept as a duplicate — ImgForge still
   supports it, so nothing breaks, and leaving two copies invites drift.
3. No `.tools/` README or manifest is required by the tools-dir spec for this change; only
   the `imgforge` subfolder is in scope.

## Phase 1 — Move the configuration

- [x] `git mv .imgforge/template.html .tools/imgforge/template.html`
- [x] `git mv .imgforge/deviq-icon-300x300.png .tools/imgforge/deviq-icon-300x300.png`
- [x] Confirm `.imgforge/` no longer exists and the relative watermark `src` in
      `template.html` still resolves (both files in the same folder — no edit needed).
- [x] Confirm `.gitignore` does not exclude `.tools/` (it does not).

## Phase 2 — Update documentation

- [x] `README.md` → "Creating a Featured Image": update the template path to
      `.tools/imgforge`, mention ImgForge 0.2.0 and the tools-dir location, and note that
      `--template` may be omitted inside the repo.
- [x] `.claude/skills/deviq-article/SKILL.md` → "Generating one with ImgForge": update the
      `dnx` command and the `.imgforge/template.html` reference to `.tools/imgforge/...`.
- [x] Grep the whole repo (excluding `.git`) for `imgforge` / `.imgforge` to be sure nothing
      else references the old path (`.claude/agents/`, `.agents/plans/`, `scripts/`,
      `archetypes/`, `content/`, `AGENTS.md`).

## Phase 3 — Verification / test requirements

This is a Hugo content site with **no automated test project**, so the "tests" for this
change are the repo's real verification commands plus one functional end-to-end run of the
tool against the moved configuration. There is no unit/integration/e2e test project to add
coverage to; inventing one is out of scope for this issue.

- [x] **Functional check (the real test for this change):** run ImgForge 0.2.0 against the
      new location and confirm a DevIQ-watermarked PNG is produced:
      `dnx -y imgforge -- generate --title "ImgForge Tools Dir Test" --bg random --template .tools/imgforge --format blog --out <temp>.png`
      Then **view the PNG** to confirm the watermark rendered (proves the relative asset path
      survived the move). Delete the temp PNG afterwards — it is not site content.
- [x] **Implicit-discovery check:** run the same command with `--template` omitted and
      confirm ImgForge resolves `.tools/imgforge/template.html` (and no legacy tip is
      printed).
- [x] `hugo build` — no `ERROR` lines.
- [x] `markdownlint README.md` (and the skill file) — only `MD013/line-length` fires, and
      only because this repo writes markdown prose as long unwrapped lines throughout
      (36 pre-existing MD013 hits in these two files at `HEAD`; 40 after, the 4 new ones
      being my added prose lines, matching the surrounding style). No other rule fires and
      there is no `.markdownlint*` config in the repo, so MD013 is not enforced here.
- [x] `git status` — only intended files changed; no stray generated PNGs committed.

> Note: the workflow skill's default verify command (`dotnet build && dotnet test &&
> dotnet format --verify-no-changes`) does not apply — there is no .NET solution in this
> repo. The Hugo/markdownlint commands above are the project's verification per `AGENTS.md`.

## Phase 4 — Independent review

- [ ] Dispatch a **separate review agent** (fresh context) over the full diff against the
      issue's acceptance criteria. It must check: completeness (no lingering `.imgforge`
      references), correctness of the documented commands, accuracy of claims about ImgForge
      0.2.0 behavior, security, performance, and accessibility of any changed content.
- [ ] Address all significant findings; record any deliberately-skipped finding and why.
- [ ] Re-run Phase 3 verification if the review produced changes.

### Review findings

_To be filled in after the review agent runs._

## Phase 5 — Pull request

- [ ] Commit with a conventional message.
- [ ] Push the branch and open a PR targeting `main` with `Fixes #88`.
- [ ] Link the PR to this thread via `link_pull_request`.
