<div align="center">

# Hanzo

**Run the AI cloud on your own machine.**

Everything below is open source. The same code runs our cloud and yours.

[hanzo.ai](https://hanzo.ai) · [docs.hanzo.ai](https://docs.hanzo.ai) · [cloud.hanzo.ai](https://cloud.hanzo.ai)

</div>

---

## Start here — the local stack

Most AI platforms give you an API key. We give you the platform. Install one
binary and you have inference, agents, tools, and storage running locally, with
no account and no network call.

```bash
curl -fsSL https://hanzo.sh | sh     # the CLI, the MCP server, the coding agent
hanzo                                # an AI engineer in your terminal
```

Prefer a window to a prompt? [Download Hanzo Desktop](https://github.com/hanzoai/desktop/releases)
— it ships the node and the inference engine inside the app, so it works offline
on the first launch.

| | What it is |
|---|---|
| **[desktop](https://github.com/hanzoai/desktop)** | The whole stack as a desktop app. Bundles the agent node and the inference engine as sidecars — install it and you are running local AI, no config. macOS · Windows · Linux. |
| **[cli](https://github.com/hanzoai/cli)** | One static Rust binary: an AI coding agent, and every product of the Hanzo cloud from the terminal. No runtime, no daemon. |
| **[engine](https://github.com/hanzoai/engine)** | The inference engine. Fast, flexible LLM and embedding serving in Rust — the thing that actually runs the model. |
| **[ml](https://github.com/hanzoai/ml)** | The compute core underneath it: multi-backend tensors for Rust across CPU · CUDA · Metal · ROCm · Vulkan, quantization built in. |
| **[net](https://github.com/hanzoai/net)** | Pool the machines you already own — iPhone, Mac, Raspberry Pi, NVIDIA boxes — into one inference cluster. |
| **[edge](https://github.com/hanzoai/edge)** | On-device inference for mobile, web, and embedded, built on Hanzo ML. |

Local and cloud are the same API (`/v1/`). Point a client at `localhost` or at
`api.hanzo.ai` and nothing else changes.

---

## Build with AI

| | What it is |
|---|---|
| [python-sdk](https://github.com/hanzoai/python-sdk) | The most complete SDK we ship: agents, MCP tools, memory, inference, cloud. |
| [js-sdk](https://github.com/hanzoai/js-sdk) | TypeScript and JavaScript — agents, cloud, inference. |
| [java-sdk](https://github.com/hanzoai/java-sdk) · [sdk](https://github.com/hanzoai/sdk) | Typed Java client, and the index of every SDK in every language. |
| [mcp](https://github.com/hanzoai/mcp) | Model Context Protocol server — 260+ tools for agents. |
| [agent](https://github.com/hanzoai/agent) | Multi-agent framework with an OpenAI-compatible API. |
| [dev](https://github.com/hanzoai/dev) | A fast local coding agent for your terminal. |
| [code](https://github.com/hanzoai/code) | An open source AI code editor — any model, your data stays yours. |
| [extension](https://github.com/hanzoai/extension) | The same agent inside VS Code and compatible editors. |
| [app](https://github.com/hanzoai/app) | Describe an app, get an app. AI web and app builder. |
| [studio](https://github.com/hanzoai/studio) | Visual AI engine — build pipelines by wiring them up. |
| [chat](https://github.com/hanzoai/chat) · [bot](https://github.com/hanzoai/bot) | Chat with MCP and any provider; the same assistant on WhatsApp, Telegram, Slack, Discord. |
| [crawl](https://github.com/hanzoai/crawl) | Web crawling that returns LLM-ready text. |

---

## Run the cloud

These are the services behind `api.hanzo.ai`. Each is a single binary you can
run yourself.

| | What it is |
|---|---|
| [platform](https://github.com/hanzoai/platform) | The PaaS. Git push to deploy, on your own Kubernetes. |
| [console](https://github.com/hanzoai/console) | The admin and observability console for all of it. |
| [iam](https://github.com/hanzoai/iam) | Identity — OIDC, JWT, per-brand SSO. Never roll your own auth. |
| [gateway](https://github.com/hanzoai/gateway) | The trust boundary: identity, rate limiting, metering, CORS. |
| [authz](https://github.com/hanzoai/authz) · [hsm](https://github.com/hanzoai/hsm) | Access control for Go (ACL/RBAC/ABAC); HSM signers including ML-DSA. |
| [functions](https://github.com/hanzoai/functions) | Serverless compute for event-driven work. |
| [tasks](https://github.com/hanzoai/tasks) | Durable workflow execution for agent orchestration. |
| [commerce](https://github.com/hanzoai/commerce) · [finance](https://github.com/hanzoai/finance) | Orders, subscriptions, metering, credit ledger; a double-entry financial core. |
| [flags](https://github.com/hanzoai/flags) · [insights](https://github.com/hanzoai/insights) | Feature flags and A/B; product analytics. |
| [o11y](https://github.com/hanzoai/o11y) · [otel-collector](https://github.com/hanzoai/otel-collector) | OpenTelemetry-native metrics, traces, logs. |

---

## Data

| | What it is |
|---|---|
| [base](https://github.com/hanzoai/base) | The storage substrate: multi-tenant SQLite with in-process polyglot extensions and encrypted replication. |
| [datastore](https://github.com/hanzoai/datastore) | Column-oriented OLAP for real-time analytics. |
| [s3](https://github.com/hanzoai/s3) · [vfs](https://github.com/hanzoai/vfs) | S3-compatible object storage; an S3-backed virtual block filesystem. |
| [sql](https://github.com/hanzoai/sql) · [kv](https://github.com/hanzoai/kv) · [docdb](https://github.com/hanzoai/docdb) | Postgres with pgvector; a Redis-compatible key-value store; a MongoDB-compatible document database. |
| [vector](https://github.com/hanzoai/vector) · [index](https://github.com/hanzoai/index) | Vector search for embeddings; full-text, vector, and hybrid retrieval in Rust. |
| [orm](https://github.com/hanzoai/orm) · [sqlite](https://github.com/hanzoai/sqlite) · [sqlcipher](https://github.com/hanzoai/sqlcipher) | Type-safe generics ORM for Go; encrypted SQLite at rest. |
| [pubsub](https://github.com/hanzoai/pubsub) · [kafka](https://github.com/hanzoai/kafka) | Event streaming, and a Kafka wire-protocol gateway for it. |

---

## Infrastructure

| | What it is |
|---|---|
| [ingress](https://github.com/hanzoai/ingress) | Kubernetes-native L7 proxy and load balancer with automatic TLS. |
| [dns](https://github.com/hanzoai/dns) | Programmable DNS — CoreDNS with Hanzo plugins. |
| [git](https://github.com/hanzoai/git) | Self-hosted Git, code review, package registry, and CI in one service. |
| [ci](https://github.com/hanzoai/ci) · [cd](https://github.com/hanzoai/cd) · [pack](https://github.com/hanzoai/pack) | Build, test, and deploy any repo from one `hanzo.yml`; declarative CD for Kubernetes; zero-config BuildKit builds. |
| [registry](https://github.com/hanzoai/registry) | Container registry with Hanzo IAM token auth. |
| [mail](https://github.com/hanzoai/mail) | Self-hosted mail — SMTP, IMAP, webmail, DKIM/SPF/DMARC. |

---

## Applications

Complete products, open source, running on the stack above.

[cms](https://github.com/hanzoai/cms) · [erp](https://github.com/hanzoai/erp) ·
[helpdesk](https://github.com/hanzoai/helpdesk) · [esign](https://github.com/hanzoai/esign) ·
[captable](https://github.com/hanzoai/captable) · [dataroom](https://github.com/hanzoai/dataroom) ·
[cal](https://github.com/hanzoai/cal) · [social](https://github.com/hanzoai/social) ·
[world](https://github.com/hanzoai/world) · [tabs](https://github.com/hanzoai/tabs) ·
[frames](https://github.com/hanzoai/frames)

## Design

[ui](https://github.com/hanzoai/ui) · [gui](https://github.com/hanzoai/gui) ·
[shadcn](https://github.com/hanzoai/shadcn) · [svelte](https://github.com/hanzoai/svelte) ·
[design](https://github.com/hanzoai/design) · [brand](https://github.com/hanzoai/brand) ·
[logo](https://github.com/hanzoai/logo) · [gallery](https://github.com/hanzoai/gallery)

## Go libraries

Small, single-purpose, no framework attached.

[money](https://github.com/hanzoai/money) · [decimal](https://github.com/hanzoai/decimal) ·
[doctype](https://github.com/hanzoai/doctype) · [framework](https://github.com/hanzoai/framework) ·
[migrate](https://github.com/hanzoai/migrate) · [notify](https://github.com/hanzoai/notify) ·
[research](https://github.com/hanzoai/research)

---

<div align="center">

Read the [papers](https://github.com/hanzoai/papers) · Ship on [cloud.hanzo.ai](https://cloud.hanzo.ai)

Hanzo AI, Inc. — Techstars '17

</div>
