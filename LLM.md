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

## Pointers
hanzo.ai · docs.hanzo.ai · cloud.hanzo.ai · SDK index `hanzoai/sdk` · spec `hanzoai/openapi`.
