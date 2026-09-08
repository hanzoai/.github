# hanzoai — org guide for AI agents

`hanzoai` is the umbrella / front-door org for **Hanzo — the Open AI Cloud**:
a full AI SDK and AI cloud (models, agents, tools, memory, MCP, inference) plus
compute, data, network, security, platform, and web3 primitives.

## Canonical SDK model (two lines, every language)
1. **Full Cloud SDK** — generated from the cloud OpenAPI (`hanzoai/openapi`),
   covers the whole `/v1/` surface. Real code lives in the per-language org as
   `hanzo-<lang>/sdk` (hanzo-js, hanzo-go, hanzo-py, hanzo-rs, hanzo-cpp,
   hanzo-swift, hanzo-kt). Docs/landing wrapper = `hanzoai/<lang>-sdk`.
   Meta index = `hanzoai/sdk`.
2. **AI / Agents SDK** — hand-crafted flagship (models, agents, tools, memory,
   MCP). Python `hanzo` (`hanzoai/python-sdk`, most complete); Node `@hanzo/ai`
   (`hanzo-js/ai`). Completeness order: Python → Rust → C++ → Go → others.

Real code lives in the **per-language orgs**; this umbrella holds product apps
and the SDK wrappers/docs. Full spec: `~/work/hanzo/SDK-ARCHITECTURE.md`.

## Install
```bash
pip install hanzo          # Python — flagship AI + agents SDK
npm  install @hanzo/ai     # TypeScript / JavaScript
```

## Brand rules (hard — never violate)
- Hanzo is a **full AI SDK / AI cloud**, NOT an "LLM gateway" or proxy. Never
  position against LiteLLM. Purge that framing.
- **Zen** models are our own family (Zen MoDE) — never name upstream models.
- API paths are **`/v1/`** only — never an `/api/` prefix, never bump to v2.
- Positioning: "Hanzo — the Open AI Cloud. Open source. Every language. On-chain settlement."

## CI (hard) — `.github/workflows` is a sync, not an orchestrator
A repo's `.github/workflows` holds exactly ONE file: a nudge telling git.hanzo.ai
a push happened. Real CI lives in `.hanzo/workflows` and runs on our own runners
(`hanzo-linux-amd64` and friends — RUNNERS.md is the label taxonomy). Reference
shape: `hanzoai/app`. The law is enforced here by `scripts/workflow-law.py`.

Two facts that decide every migration:
- **The forge picks ONE workflow dir.** `hanzoai/forge`
  `modules/actions/workflows.go:listWorkflowsInDirs` walks
  `.hanzo/workflows`, `.gitea/workflows`, `.github/workflows` and BREAKS at the
  first that exists. Once a repo has `.hanzo/workflows`, its `.github/workflows`
  is invisible natively — one dir wins, nothing merges.
- **A mirror sync DOES fire Actions**, so converting a repo from pull mirror to
  canonical is a question about who owns `main`, NOT a precondition for native
  CI (`services/mirror/mirror_pull.go` → `notify_service.SyncPushCommits` →
  `services/actions/notifier.go`). What gates it is the repo's **Actions unit**:
  `has_actions: false` ⇒ zero native runs, however good the workflow file is.
  Check it before deleting a repo's last working GitHub workflow.

This repo is the ONE bounded exception: `.github/workflows` also publishes the
org's reusable workflows (`uses: hanzoai/.github/.github/workflows/<n>.yml@main`,
~90 callers). Those are `on: workflow_call` only — an interface, never a runner.

### Two ways to break every caller at once

Both fail with **0 jobs and no log**, which is why they hide. A reusable is an
interface: a mistake in its header is a mistake in ~90 repos.

- **No `${{ }}` anywhere in the header, not even in prose.** GitHub evaluates
  templates inside every string scalar, and `workflow_call.inputs.<id>.description`
  allows no contexts at all. One `${{ github.… }}` in a *comment about* an input
  is a 422 for every caller: `Unrecognized named-value`. `#` comments are safe,
  YAML scalars are not. The error reports the line where a folded scalar OPENS,
  and the sha of the resolved branch head — neither points at the mistake, so
  read the whole scalar and `git log -p` the file rather than trusting either.
  `actionlint` catches it; its column is an offset INTO the flattened scalar,
  so a column of ~1100 on a 100-char file is real, not noise.
- **Never request a permission no step reads.** A called workflow may only
  narrow what the caller granted, so a job asking for `id-token: write` kills
  the run at startup for any caller that did not grant it — and `id-token`
  defaults to `none`. `docker-build.yml` asked for it in five jobs and read it
  in none, which silently locked out 30 of 49 callers. Grep the jobs for a real
  consumer (`cosign sign`, `attest`, `fulcio`, `ACTIONS_ID_TOKEN`) before adding
  one; `cosign attach sbom` uses registry credentials, not OIDC.

The forge's act-based parser accepts both, so canonical CI stays green while
every GitHub caller dies. When a reusable is suspect, test it on GitHub.

## Pointers
hanzo.ai · docs.hanzo.ai · cloud.hanzo.ai · SDK index `hanzoai/sdk` · spec `hanzoai/openapi`.
Conventions — commits, naming, comments, architecture, TypeScript, Go, whitespace — are
`hanzoai/styleguide` (MIT OR Apache-2.0); `zooai/styleguide` and `luxfi/styleguide` carry
only their org's delta and point back at it.

## License

Dual-licensed **MIT OR Apache-2.0** (`LICENSE-MIT`, `LICENSE-APACHE`), replacing the
previous BSD-3-Clause declaration. Original Hanzo work standardises on this pair per
HIP-0137 "One License" (`hanzoai/hips`, `HIPs/hip-0137-one-license.md`); forks keep
their upstream licence unchanged.
