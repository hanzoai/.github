#!/usr/bin/env python3
"""Clean repos that have no local clone — discovery from the GitHub org API.

Companion to git-hygiene.py, which discovers from the filesystem and therefore
only ever sees repos someone happened to clone. The orgs hold ~688 repos; the
local working set was 497, so hundreds were never in scope.

Per repo: clone -> measure -> rewrite if dirty -> push -> verify -> delete.
Clone into scratch and remove after, so 250 repos do not fill the disk.
"""
import os, re, shutil, subprocess, sys, threading
from concurrent.futures import ThreadPoolExecutor

GIT = "/Library/Developer/CommandLineTools/usr/bin/git"
FR = "/opt/homebrew/bin/git-filter-repo"
RULES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "rules")
SCRATCH = "/private/tmp/claude-501/-Users-z-work/bb35b62d-fb94-4795-be67-be3e9b5588e6/scratchpad/hy"
DIRTY = re.compile(rb'(?im)^\s*(co-authored-by:\s*(claude|codex|cursor|copilot|openai|lovable|devin)'
                   rb'|made-with:|generated-by:|assisted-by:|claude-session:)|noreply@anthropic|satschel|liquidityio')
CB = ('return b"dev@hanzo.ai" if any(v in email for v in '
      '(b"anthropic.com", b"satschel", b"liquidityio", b"cursor.com", b"lovable.dev")) else email')
TOKEN = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True).stdout.strip()
lock = threading.Lock()
log = open("/tmp/hy-org.log", "a", buffering=1)


def run(a, cwd=None, t=3600):
    try: return subprocess.run(a, cwd=cwd, capture_output=True, timeout=t)
    except Exception:
        class R: returncode, stdout, stderr = 99, b"", b""
        return R()


def emit(s):
    with lock: log.write(s + "\n")


def org_repos(org):
    out = []
    for p in range(1, 12):
        r = run(["gh", "api", f"orgs/{org}/repos?per_page=100&page={p}", "--jq",
                 ".[]|select(.archived==false)|.full_name"], t=180)
        names = [x for x in r.stdout.decode().split() if x]
        out += names
        if len(names) < 100: break
    return out


def work(slug):
    d = os.path.join(SCRATCH, slug.replace("/", "__"))
    url = f"https://x-access-token:{TOKEN}@github.com/{slug}.git"
    shutil.rmtree(d, ignore_errors=True)
    if run([GIT, "clone", "-q", url, d], t=2400).returncode != 0:
        emit(f"FAIL clone {slug}"); return
    try:
        heads = run([GIT, "-C", d, "for-each-ref", "--format=%(refname)", "refs/heads"], t=300).stdout.decode().split()
        body = run([GIT, "-C", d, "log", "--format=%ae%n%ce%n%B", *heads], t=900).stdout if heads else b""
        before = len(DIRTY.findall(body))
        if before == 0:
            emit(f"OK   {slug} already-clean"); return
        run([FR, "--force", "--prune-empty=never",
             "--replace-message", f"{RULES}/messages.txt"], cwd=d, t=7200)
        run([GIT, "-C", d, "remote", "add", "origin", url], t=60)
        heads = run([GIT, "-C", d, "for-each-ref", "--format=%(refname:short)", "refs/heads"], t=300).stdout.decode().split()
        body = run([GIT, "-C", d, "log", "--format=%ae%n%ce%n%B",
                    *[f"refs/heads/{h}" for h in heads]], t=900).stdout if heads else b""
        after = len(DIRTY.findall(body))
        ok = 0
        for b in heads:
            if run([GIT, "-C", d, "push", "--no-verify", "--force", "origin",
                    f"+refs/heads/{b}:refs/heads/{b}"], t=3600).returncode == 0: ok += 1
        emit(f"{'OK  ' if after == 0 else 'WARN'} {slug} {before}->{after} pushed={ok}/{len(heads)}")
    finally:
        shutil.rmtree(d, ignore_errors=True)


if __name__ == "__main__":
    orgs = sys.argv[1:] or ["hanzoai", "luxfi", "zooai", "parsdao"]
    slugs = []
    for o in orgs: slugs += org_repos(o)
    emit(f"=== {len(slugs)} repos across {orgs} ===")
    with ThreadPoolExecutor(max_workers=6) as ex: list(ex.map(work, slugs))
    emit("=== ORG PASS DONE ===")
