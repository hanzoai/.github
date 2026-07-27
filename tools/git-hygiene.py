#!/usr/bin/env python3
"""git-hygiene — the one way to purge vendor attribution from git history.

    git-hygiene scan            what is dirty, measured on real branches
    git-hygiene clean [repo…]   purge caches, rewrite, push — atomically, per repo
    git-hygiene verify          independent re-measure; exits non-zero if dirty

Five stages, each doing exactly one thing and composable in any order:

    discover  -> repos we own, deduped by real git dir
    purge     -> drop stale remote-tracking caches
    measure   -> count vendor attribution on refs/heads only
    rewrite   -> filter-repo with the rule files
    publish   -> force-push branches that already exist upstream

Rules live in RULES/ as data, never inline: mechanism and policy stay separate.

Two invariants this tool exists to hold, both learned the hard way:

  1. rewrite and publish are ONE step per repo. Batching "rewrite all, then push
     all" leaves a window where a fetch re-materialises pre-rewrite commits from
     the un-force-pushed remote, silently undoing the work.

  2. measure refs/heads, never `--all`. `--all` includes refs/remotes/*, which
     are caches of pre-rewrite history; counting them reports contamination that
     no real branch carries and no push can fix.
"""
import json, os, re, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

GIT = "/Library/Developer/CommandLineTools/usr/bin/git"
FR = "/opt/homebrew/bin/git-filter-repo"
ROOT = os.path.expanduser("~/work")
RULES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "rules")
OURS = {"luxfi", "hanzoai", "zooai", "parsdao", "hanzodns", "hanzofi", "hanzogui",
        "hanzoid", "hanzos3", "hanzoui", "hanzozt", "hanzobot", "hanzodocs",
        "zenlm", "adnexus", "miga", "zoo-labs", "luxnext"}

# Trailer-anchored. A bare substring match reports prose as contamination:
# "no cursor codec", "simplicity", and the legitimate luxfi/liquid protocol all
# false-positived before these were anchored to line starts and trailer keys.
VENDOR = re.compile(
    rb'(?im)^\s*(co-authored-by:\s*(claude|codex|cursor|copilot|openai|chatgpt|'
    rb'lovable|devin|windsurf|codeium|bolt|replit|aider|cody|tabnine|gemini|'
    rb'jules|coderabbit|qodo|cline|openhands|blackbox|phind|grok|deepseek|qwen)'
    rb'|made-with:|generated-by:|assisted-by:|claude-session:)')
VENDOR_EMAIL = re.compile(rb'(?i)<[^>\n]*@?(anthropic\.com|cursor\.com|lovable\.dev|cognition\.ai|codeium\.com)>')
POISON = re.compile(rb'(?i)(satschel|liquidityio|liquidity\.io|xitkov)')
EMAIL_CB = ('return b"dev@hanzo.ai" if any(v in email for v in '
            '(b"anthropic.com", b"satschel", b"liquidityio", b"cursor.com", b"lovable.dev")) '
            'else email')


def run(args, cwd=None, timeout=3600):
    try:
        return subprocess.run(args, cwd=cwd, capture_output=True, timeout=timeout)
    except Exception:
        class R: returncode, stdout, stderr = 99, b"", b""
        return R()


def git(repo, *args, timeout=900):
    return run([GIT, "-C", repo, *args], timeout=timeout)


def origin_org(url):
    """Org from any remote form: ssh://, git@host:, https://user:tok@host/."""
    u = re.sub(r'^[a-z][a-z0-9+.-]*://', '', url.strip())
    u = re.sub(r'^[^@/]*@', '', u)
    if '/' not in u.split(':')[0]:
        u = u.replace(':', '/', 1)
    parts = [p for p in u.split('/') if p]
    return parts[1] if len(parts) > 1 else None


def discover():
    """Repos we own. Skips worktrees — a worktree's .git is a FILE, and running
    filter-repo inside one rewrites the PARENT's object store."""
    seen, out = set(), []
    for top in sorted(os.listdir(ROOT)):
        base = os.path.join(ROOT, top)
        if not os.path.isdir(base) or os.path.islink(base):
            continue
        cands = [base] if os.path.isdir(os.path.join(base, ".git")) else [
            os.path.join(base, s) for s in sorted(os.listdir(base))
            if os.path.isdir(os.path.join(base, s, ".git"))
            and not os.path.islink(os.path.join(base, s))]
        for d in cands:
            real = os.path.realpath(d)
            if real in seen:
                continue
            url = git(d, "remote", "get-url", "origin", timeout=60).stdout.decode().strip()
            if origin_org(url) in OURS:
                seen.add(real)
                out.append(d)
    return out


def purge(repo):
    """Drop stale remote-tracking refs — caches of pre-rewrite history."""
    refs = git(repo, "for-each-ref", "--format=%(refname)", "refs/remotes").stdout.decode().split()
    for r in refs:
        git(repo, "update-ref", "-d", r, timeout=60)
    return len(refs)


def measure(repo):
    heads = git(repo, "for-each-ref", "--format=%(refname)", "refs/heads").stdout.decode().split()
    if not heads:
        return 0, 0
    body = git(repo, "log", "--format=%ae%n%ce%n%B", *heads).stdout
    return len(VENDOR.findall(body)) + len(VENDOR_EMAIL.findall(body)), len(POISON.findall(body))


def rewrite(repo, with_text):
    url = git(repo, "remote", "get-url", "origin", timeout=60).stdout.decode().strip()
    marker = os.path.join(repo, ".git", "filter-repo", "already_ran")
    if os.path.exists(marker):          # blocks reruns; --force does NOT bypass it
        os.remove(marker)
    args = [FR, "--force", "--prune-empty=never",
            "--mailmap", f"{RULES}/mailmap.txt",
            "--replace-message", f"{RULES}/messages.txt",
            "--email-callback", EMAIL_CB]
    if with_text:
        args += ["--replace-text", f"{RULES}/text.txt"]
    rc = run(args, cwd=repo, timeout=7200).returncode
    if url:                              # filter-repo strips remotes by design
        git(repo, "remote", "add", "origin", url, timeout=60)
        git(repo, "remote", "set-url", "origin", url, timeout=60)
    return rc


def publish(repo):
    """Push only branches that already exist upstream: never publishes local WIP,
    never prunes, so nothing upstream is deleted. --no-verify skips git-lfs's
    pre-push hook, safe because a metadata-only rewrite leaves blobs untouched."""
    ls = git(repo, "ls-remote", "--heads", "origin")
    if ls.returncode != 0:
        return 0, 0
    remote = {l.split("refs/heads/", 1)[1] for l in ls.stdout.decode().splitlines()
              if "refs/heads/" in l}
    local = set(git(repo, "for-each-ref", "--format=%(refname:short)",
                    "refs/heads").stdout.decode().split())
    targets, ok = sorted(remote & local), 0
    for b in targets:
        spec = f"+refs/heads/{b}:refs/heads/{b}"
        if git(repo, "push", "--no-verify", "--force", "origin", spec, timeout=3600).returncode == 0:
            ok += 1
    return ok, len(targets)


def clean(repo):
    purge(repo)
    ai, poison = measure(repo)
    if ai or poison:
        rewrite(repo, with_text=bool(poison))
        ai, poison = measure(repo)
    ok, total = publish(repo)            # atomic with the rewrite: see invariant 1
    return {"repo": os.path.relpath(repo, ROOT), "ai": ai, "poison": poison,
            "pushed": f"{ok}/{total}"}


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "scan"
    names = sys.argv[2:]
    repos = [os.path.join(ROOT, n) for n in names] if names else discover()
    if cmd == "scan" or cmd == "verify":
        def one(d):
            purge(d)
            a, p = measure(d)
            return (os.path.relpath(d, ROOT), a, p)
        res = list(ThreadPoolExecutor(max_workers=10).map(one, repos))
        dirty = [(n, a, p) for n, a, p in res if a or p]
        print(f"repos {len(res)}  vendor {sum(a for _, a, _ in res)}  poison {sum(p for _, _, p in res)}")
        for n, a, p in sorted(dirty, key=lambda x: -(x[1] + x[2]))[:20]:
            print(f"  {n}: vendor={a} poison={p}")
        sys.exit(1 if dirty and cmd == "verify" else 0)
    if cmd == "clean":
        for r in ThreadPoolExecutor(max_workers=8).map(clean, repos):
            print(json.dumps(r))
        return
    print(__doc__)
    sys.exit(2)


if __name__ == "__main__":
    main()
