<div align="center">

# Hanzo — the Open AI Cloud

**Open source. Every language. On-chain settlement.**

A full AI SDK and AI cloud: models, agents, tools, memory, MCP, inference —
plus the compute, data, network, security, and platform primitives to ship them.

[![Website](https://img.shields.io/badge/Website-hanzo.ai-111111?style=flat-square)](https://hanzo.ai)
[![Docs](https://img.shields.io/badge/Docs-docs.hanzo.ai-2563eb?style=flat-square)](https://docs.hanzo.ai)
[![Cloud](https://img.shields.io/badge/Open_AI_Cloud-GCP--compatible-16a34a?style=flat-square)](https://cloud.hanzo.ai)
[![Techstars](https://img.shields.io/badge/Techstars-'17-e11d48?style=flat-square)](https://hanzo.ai)

</div>

---

Hanzo is the **Open AI Cloud** — an open-source, GCP-compatible platform with
on-chain settlement. One API surface (`/v1/`), idiomatic SDKs in every language,
and a flagship AI/agents library. Build with our own **Zen** model family, run
anywhere, and settle usage on-chain.

```bash
pip install hanzo          # Python — flagship AI + agents SDK
npm  install @hanzo/ai     # TypeScript / JavaScript
```

- **Start here:** [hanzo.ai](https://hanzo.ai) · [docs.hanzo.ai](https://docs.hanzo.ai) · [cloud.hanzo.ai](https://cloud.hanzo.ai)
- **SDK index:** [hanzoai/sdk](https://github.com/hanzoai/sdk) — one install, every service, every language
- **API spec:** [hanzoai/openapi](https://github.com/hanzoai/openapi) — OpenAPI 3.1, the single source of truth

---

## SDKs — every language, two lines

Every language ships **two** SDKs, and there is only ever one way to build each:

1. **Full Cloud SDK** — generated from our [OpenAPI](https://github.com/hanzoai/openapi)
   spec, covering the entire `/v1/` surface. Real, idiomatic code lives in the
   per-language ecosystem org as **`hanzo-<lang>/sdk`**.
2. **AI / Agents SDK** — the hand-crafted flagship: models, agents, tools,
   memory, MCP, inference.

The per-language orgs hold the real code — proof we genuinely adopt and love
each ecosystem. A docs/landing wrapper (`hanzoai/<lang>-sdk`) lives here in the
umbrella so everything is discoverable in one place.

| Language | Ecosystem org | Cloud SDK (real code) | AI / Agents SDK |
|----------|---------------|-----------------------|-----------------|
| **Python** &nbsp;·&nbsp; _flagship, most complete_ | [hanzo-py](https://github.com/hanzo-py) | [hanzoai/python-sdk](https://github.com/hanzoai/python-sdk) | [hanzoai/python-sdk](https://github.com/hanzoai/python-sdk) &nbsp;`hanzo` |
| TypeScript / JavaScript | [hanzo-js](https://github.com/hanzo-js) | [hanzo-js/sdk](https://github.com/hanzo-js/sdk) | [hanzo-js/ai](https://github.com/hanzo-js/ai) &nbsp;`@hanzo/ai` |
| Rust | [hanzo-rs](https://github.com/hanzo-rs) | [hanzo-rs/sdk](https://github.com/hanzo-rs/sdk) | — |
| Go | [hanzo-go](https://github.com/hanzo-go) | [hanzo-go/sdk](https://github.com/hanzo-go/sdk) | — |
| C++ | [hanzo-cpp](https://github.com/hanzo-cpp) | [hanzo-cpp/sdk](https://github.com/hanzo-cpp/sdk) | — |
| Swift | [hanzo-swift](https://github.com/hanzo-swift) | _in progress_ | — |
| Kotlin | [hanzo-kt](https://github.com/hanzo-kt) | _in progress_ | — |

Umbrella docs/landing wrappers: [js-sdk](https://github.com/hanzoai/js-sdk) ·
[python-sdk](https://github.com/hanzoai/python-sdk) ·
[ruby-sdk](https://github.com/hanzoai/ruby-sdk) ·
[java-sdk](https://github.com/hanzoai/java-sdk) ·
[dart-sdk](https://github.com/hanzoai/dart-sdk).
Completeness order (investment priority): **Python → Rust → C++ → Go → others.**

---

## AI & Agents

The AI-first stack — the flagship of the whole platform.

| Repo | What it is |
|------|------------|
| [python-sdk](https://github.com/hanzoai/python-sdk) | **Flagship** AI + agents toolkit for Python: `hanzo`, `hanzo-agent`, `hanzo-mcp`, `hanzo-memory`, inference — the most complete SDK we ship. |
| [hanzo-js/ai](https://github.com/hanzo-js/ai) | `@hanzo/ai` — the Node/TypeScript AI + agents library. |
| [agent](https://github.com/hanzoai/agent) | Multi-agent SDK with an OpenAI-compatible API. |
| [mcp](https://github.com/hanzoai/mcp) | Model Context Protocol server — 260+ tools for AI agents. |
| [memory](https://github.com/hanzoai/memory) | Persistent memory API for agents and applications. |
| [tools](https://github.com/hanzoai/tools) | Reusable tool library for AI agents. |
| [operative](https://github.com/hanzoai/operative) | Autonomous computer-use agent. |
| [ai](https://github.com/hanzoai/ai) | AI control plane — RAG, model hub, and native Go routing. |
| [engine](https://github.com/hanzoai/engine) | Rust inference engine for LLM & embedding models. |
| [router](https://github.com/hanzoai/router) | Pure-Rust, memory- & engine-aware model-routing core. |
| [node](https://github.com/hanzoai/node) | Rust AI-agent node with an on-chain interface. |

---

## Cloud & Platform

The services behind [cloud.hanzo.ai](https://cloud.hanzo.ai) and `api.hanzo.ai`.

| Repo | What it is |
|------|------------|
| [cloud](https://github.com/hanzoai/cloud) | Unified Go binary importing every Hanzo-native subsystem. |
| [gateway](https://github.com/hanzoai/gateway) | High-performance API gateway at `api.hanzo.ai` — routing, JWT/IAM. |
| [iam](https://github.com/hanzoai/iam) | Identity & access management — OIDC, JWT, per-brand SSO. |
| [id](https://github.com/hanzoai/id) | Hosted, per-org login pages for Hanzo IAM. |
| [base](https://github.com/hanzoai/base) | Multi-tenant SQLite backend with in-process polyglot extensions. |
| [platform](https://github.com/hanzoai/platform) | Unified PaaS for deploying AI applications. |
| [console](https://github.com/hanzoai/console) | Admin console for Hanzo Cloud and every cloud product. |
| [chat](https://github.com/hanzoai/chat) | AI chat with MCP integration and multi-provider support. |
| [bot](https://github.com/hanzoai/bot) | Personal AI assistant across WhatsApp, Telegram, and more. |
| [search](https://github.com/hanzoai/search) | AI-powered search with a generative UI. |
| [commerce](https://github.com/hanzoai/commerce) | AI-powered e-commerce platform. |
| [vault](https://github.com/hanzoai/vault) | PCI-compliant card tokenization vault. |
| [functions](https://github.com/hanzoai/functions) | Serverless compute for event-driven workloads. |
| [vector](https://github.com/hanzoai/vector) | High-performance vector database for AI embeddings. |
| [registry](https://github.com/hanzoai/registry) | Container registry with Hanzo IAM token auth. |

Secrets & keys are managed by **KMS** at [kms.hanzo.ai](https://kms.hanzo.ai).

---

## Infrastructure & OSS

Cloud-native building blocks — open source, composable, one way to do each thing.

| Repo | What it is |
|------|------------|
| [ingress](https://github.com/hanzoai/ingress) | Kubernetes-native L7 reverse proxy and load balancer. |
| [static](https://github.com/hanzoai/static) | Feature-rich static file server as an Ingress plugin. |
| [operator](https://github.com/hanzoai/operator) | Kubernetes operator for Gateway and Ingress. |
| [s3](https://github.com/hanzoai/s3) | S3-compatible distributed object storage. |
| [sqlite](https://github.com/hanzoai/sqlite) | Encrypted SQLite driver for at-rest data protection. |
| [replicate](https://github.com/hanzoai/replicate) | Streaming replication for SQLite. |
| [orm](https://github.com/hanzoai/orm) | Generics-based, type-safe ORM for Go. |
| [authz](https://github.com/hanzoai/authz) | Access-control library for Go — ACL, RBAC, ABAC. |
| [dns](https://github.com/hanzoai/dns) | CoreDNS fork with Hanzo plugins for programmable DNS. |
| [o11y](https://github.com/hanzoai/o11y) | OpenTelemetry-native observability — metrics, traces, logs. |
| [analytics](https://github.com/hanzoai/analytics) | Privacy-focused web analytics. |
| [flow](https://github.com/hanzoai/flow) | Visual drag-and-drop AI workflow builder. |
| [git](https://github.com/hanzoai/git) | Self-hosted all-in-one software-development service. |

**Developer tools:** [cli](https://github.com/hanzoai/cli) ·
[dev](https://github.com/hanzoai/dev) ·
[code](https://github.com/hanzoai/code) ·
[desktop](https://github.com/hanzoai/desktop) ·
[app](https://github.com/hanzoai/app) &nbsp;&nbsp;
**UI:** [ui](https://github.com/hanzoai/ui) ·
[gui](https://github.com/hanzoai/gui) ·
[theming](https://github.com/hanzoai/theming)

---

## Zen models

**Zen** is our own frontier model family, spanning **600M – 480B** parameters —
built on **Zen MoDE (Mixture of Diverse Experts)**. Text, vision, audio, and
tool-use, tuned for agents and served through the Hanzo Cloud.

→ [hanzoai/zen](https://github.com/hanzoai/zen)

---

<div align="center">

**[hanzo.ai](https://hanzo.ai)** · **[docs.hanzo.ai](https://docs.hanzo.ai)** · **[cloud.hanzo.ai](https://cloud.hanzo.ai)**

_Hanzo AI, Inc. — Techstars '17. Building the Open AI Cloud._

</div>
