#!/usr/bin/env python3
"""Verify featured images are wired up correctly across DevIQ content.

For each article this checks four things agree, plus that the file exists:

  1. front matter  params.image        -> feeds og:image
  2. body          ![alt](./images/x)  -> what readers actually see
  3. rendered      <img src=...>       -> Hugo emitted it
  4. meta          og:image            -> social previews

Run `hugo build` first; this reads the generated site in public/.

Usage:
    python .claude/skills/deviq-article/verify_images.py [section ...]

With no arguments, checks every section. Exits non-zero if anything failed.

Note that only `laws` is currently clean. A repo-wide run reports ~86
articles in other sections that set params.image without ever showing it,
which is a latent gap rather than a regression you introduced. Pass the
section you are working on so the output is about your change.
"""

import glob
import os
import re
import sys

FM = re.compile(r"^---\r?\n(.*?\r?\n)---\r?\n", re.S)
FM_IMAGE = re.compile(r"^\s+image:\s*(\S+?)\s*$", re.M)
BODY_IMAGE = re.compile(r"!\[[^\]]*\]\(([^)]+)\)")
OG_IMAGE = re.compile(r'og:image"\s*content="([^"]+)"')


def check(path):
    """Return (status, detail) for one article.

    status is 'ok', 'skip' (no featured image declared or expected), or 'fail'.
    """
    section = path.replace("\\", "/").split("/")[1]
    slug = os.path.basename(path)[:-3]
    raw = open(path, "rb").read().decode("utf-8", errors="replace")

    m = FM.match(raw)
    if not m:
        return "fail", "no front matter"

    fm_match = FM_IMAGE.search(m.group(1))
    fm_image = os.path.basename(fm_match.group(1)) if fm_match else None

    body = raw[m.end():].lstrip("\r\n")
    top_match = BODY_IMAGE.match(body)
    body_image = os.path.basename(top_match.group(1)) if top_match else None

    if not fm_image and not body_image:
        return "skip", "no featured image"

    html_path = os.path.join("public", section, slug, "index.html")
    if not os.path.isfile(html_path):
        return "fail", f"page not built: {html_path} (run hugo build)"
    html = open(html_path, encoding="utf-8", errors="replace").read()

    og_match = OG_IMAGE.search(html)
    og_image = os.path.basename(og_match.group(1)) if og_match else None

    problems = []
    if not fm_image:
        problems.append("shows an image but has no params.image (no og:image)")
    if not body_image:
        problems.append("sets params.image but never shows it on the page")
    if fm_image and body_image and fm_image != body_image:
        problems.append(f"front matter ({fm_image}) != body ({body_image})")
    if fm_image and og_image != fm_image:
        problems.append(f"og:image is {og_image}, expected {fm_image}")
    if body_image:
        if not re.search(r'src="[^"]*' + re.escape(body_image) + r'"', html):
            problems.append(f"{body_image} not rendered in the page")
        elif not os.path.isfile(os.path.join("public", section, "images", body_image)):
            problems.append(f"{body_image} missing from public/{section}/images/")

    if problems:
        return "fail", "; ".join(problems)
    return "ok", fm_image


def main(argv):
    if not os.path.isdir("content"):
        print("Run this from the repository root.", file=sys.stderr)
        return 2

    sections = argv[1:] or sorted(
        d for d in os.listdir("content") if os.path.isdir(os.path.join("content", d))
    )

    failures = skipped = passed = 0
    for section in sections:
        files = sorted(glob.glob(f"content/{section}/*.md"))
        if not files:
            print(f"no such section: {section}", file=sys.stderr)
            failures += 1
            continue
        for path in files:
            if os.path.basename(path) == "_index.md":
                continue
            status, detail = check(path)
            slug = os.path.basename(path)[:-3]
            if status == "fail":
                failures += 1
                print(f"FAIL  {section}/{slug}: {detail}")
            elif status == "skip":
                skipped += 1
            else:
                passed += 1

    print(f"\n{passed} ok, {failures} failed, {skipped} without a featured image")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
