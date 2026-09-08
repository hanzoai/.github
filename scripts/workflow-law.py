#!/usr/bin/env python3
"""Enforce the native-CI law on the workflows this repo ships.

THE LAW: nothing under `.github/workflows` orchestrates. All real CI lives in
`.hanzo/workflows` and runs on our own runners (`act_runner`, registered against
Hanzo Git).

hanzoai/.github is the ONE bounded exception: it is also the org's reusable-
workflow API, consumed as `uses: hanzoai/.github/.github/workflows/<n>.yml@main`.
A file under `.github/workflows` here is that API — `workflow_call` only, never
firing on its own. The forge learns about a push by pulling every ten minutes
(`.hanzo/workflows/sync-from-github.yml`), so a nudge from this side would need
a GitHub-hosted runner this org cannot buy. `sync.yml` remains the one name
allowed to self-fire if that ever changes.

Run it anywhere: `python3 scripts/workflow-law.py` (no dependencies).
"""
from __future__ import annotations

import pathlib
import re
import sys

GHA = pathlib.Path(".github/workflows")
NATIVE = pathlib.Path(".hanzo/workflows")
SYNC = "sync.yml"

# GitHub-hosted runner images. Never ours, and on this org not even available:
# a GitHub-hosted job is refused outright — "recent account payments have failed
# or your spending limit needs to be increased" (measured on hanzoai/commerce,
# 2026-07-25). Every job we run, including the one-curl nudge, belongs on a pool
# from RUNNERS.md. On git.hanzo.ai act_runner does advertise these names as
# compat aliases, so a stray `ubuntu-latest` there silently means "whatever the
# runner decides" instead of a named capability.
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

    if HOSTED.search(text):
        fail(path, "GitHub-hosted runner — jobs run on our pools (RUNNERS.md); GitHub-hosted minutes are billing-blocked for this org")

    if path.parent == GHA:
        if path.name == SYNC:
            if ORCHESTRATION.search(text):
                fail(path, "the sync nudge must not build, push or deploy — that belongs in .hanzo/workflows")
        elif triggers(text) != {"workflow_call"}:
            fail(path, "self-firing GitHub workflow — only sync.yml may fire; everything else here is `on: workflow_call` API")

if not list(NATIVE.glob("*.yml")):
    failures.append(f"{NATIVE}: empty — real CI must exist natively before GitHub Actions is trimmed")

if failures:
    print("Native-CI law violated:")
    for line in failures:
        print(f"- {line}")
    sys.exit(1)
print(f"native-CI law: OK ({len(list(GHA.glob('*.yml')))} GitHub files, "
      f"{len(list(NATIVE.glob('*.yml')))} native)")
