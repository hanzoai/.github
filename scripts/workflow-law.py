#!/usr/bin/env python3
"""Enforce the native-CI law on the workflows this repo ships.

THE LAW: `.github/workflows` may do exactly ONE thing — tell git.hanzo.ai that
a push happened. All real CI lives in `.hanzo/workflows` and runs on our own
runners (`act_runner`, registered against Hanzo Git; `arcd` is retired, so on
github.com there is no self-hosted runner left at all).

hanzoai/.github is the ONE bounded exception: it is also the org's reusable-
workflow API, consumed as `uses: hanzoai/.github/.github/workflows/<n>.yml@main`.
So a file under `.github/workflows` here is either that API (`workflow_call`
only — it never fires on its own) or the sync nudge. Nothing else orchestrates.

Run it anywhere: `python3 scripts/workflow-law.py` (no dependencies).
"""
from __future__ import annotations

import pathlib
import re
import sys

GHA = pathlib.Path(".github/workflows")
NATIVE = pathlib.Path(".hanzo/workflows")
SYNC = "sync.yml"

# GitHub-hosted runner images. On github.com they are the ONLY thing that can
# run a job (post-arcd); on git.hanzo.ai act_runner advertises them as compat
# aliases. Naming one outside the sync nudge means the job is orchestrated by
# GitHub — the thing the law abolishes.
HOSTED = re.compile(r"^\s*runs-on:\s*\[?\s*['\"]?(ubuntu|macos|windows)-", re.M)
ORCHESTRATION = re.compile(r"build-push-action|docker\s+buildx|kubectl|helm\s+upgrade")

failures: list[str] = []


def fail(path: pathlib.Path, why: str) -> None:
    failures.append(f"{path}: {why}")


def triggers(text: str) -> set[str]:
    """Top-level keys of the `on:` block (regex, not YAML — zero deps)."""
    m = re.search(r"^on:\s*\n((?:[ \t].*\n|\n)*)", text, re.M)
    if not m:
        return set(re.findall(r"^on:\s*(\S+)", text, re.M))
    return set(re.findall(r"^  ([a-z_]+):", m.group(1), re.M))


for path in sorted(GHA.glob("*.yml")) + sorted(NATIVE.glob("*.yml")):
    text = path.read_text()
    if "\t" in text:
        fail(path, "tab character (YAML must be space-indented)")

    if path.parent == GHA:
        if path.name == SYNC:
            # The nudge is the one job that MUST run on GitHub's own runners:
            # act_runner is registered against Hanzo Git, never github.com.
            if not HOSTED.search(text):
                fail(path, "the sync nudge must run GitHub-hosted — no self-hosted runner is registered on github.com")
            if ORCHESTRATION.search(text):
                fail(path, "the sync nudge must not build, push or deploy — that belongs in .hanzo/workflows")
        else:
            if triggers(text) != {"workflow_call"}:
                fail(path, "self-firing GitHub workflow — only sync.yml may fire; everything else here is `on: workflow_call` API")
            if HOSTED.search(text):
                fail(path, "GitHub-hosted runner — reusables execute on act_runner; use a pool from RUNNERS.md")
    elif HOSTED.search(text):
        fail(path, "GitHub-hosted runner name — use the canonical <org>-<os>-<arch> pool (RUNNERS.md)")

if not (GHA / SYNC).exists():
    failures.append(f"{GHA / SYNC}: missing — GitHub must still tell the canonical forge about a push")
if not list(NATIVE.glob("*.yml")):
    failures.append(f"{NATIVE}: empty — real CI must exist natively before GitHub Actions is trimmed")

if failures:
    print("Native-CI law violated:")
    for line in failures:
        print(f"- {line}")
    sys.exit(1)
print(f"native-CI law: OK ({len(list(GHA.glob('*.yml')))} GitHub files, "
      f"{len(list(NATIVE.glob('*.yml')))} native)")
