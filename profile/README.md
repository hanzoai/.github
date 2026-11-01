<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/hanzoai/.github/main/profile/logo-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/hanzoai/.github/main/profile/logo-light.svg">
    <img src="https://raw.githubusercontent.com/hanzoai/.github/main/profile/logo-dark.svg" alt="Hanzo" width="360">
  </picture>
</p>

<h1 align="center">Hanzo — The Open AI Cloud</h1>

<p align="center">
  <strong>Sovereign, self-hostable AI infrastructure, developer platform, and agentic operating system.</strong>
  <br />
  One unified contract. Zero vendor lock-in. Self-contained across your laptop, edge nodes, or private GPU clusters.
</p>

<p align="center">
  <a href="https://hanzo.ai"><strong>hanzo.ai</strong></a> ·
  <a href="https://docs.hanzo.ai"><strong>Documentation</strong></a> ·
  <a href="https://docs.hanzo.ai/llms.txt"><strong>LLM Context (llms.txt)</strong></a> ·
  <a href="https://hips.hanzo.ai"><strong>HIPs Specifications</strong></a> ·
  <a href="https://hanzoskills.com"><strong>Skills</strong></a> ·
  <a href="https://hanzo.market"><strong>Market</strong></a> ·
  <a href="https://forge.hanzo.ai"><strong>Hanzo Forge</strong></a> ·
  <a href="https://cd.hanzo.ai"><strong>Hanzo CD</strong></a> ·
  <a href="https://auto.hanzo.ai"><strong>Auto</strong></a> ·
  <a href="https://admin.hanzo.ai"><strong>Admin</strong></a> ·
  <a href="https://hanzo.sh"><strong>CLI (hanzo.sh)</strong></a>
</p>

---

## Architecture: From Ingress to Egress

Hanzo unifies every layer of the modern cloud and AI stack into an open, zero-trust lifecycle:

```
[Clients, SDKs, Coding Agents, Browsers]
                   │
                   ▼
  Cloudflare (Edge WAF, DDoS, Anycast SSL)
                   │
                   ▼
  hanzoai/ingress (L4/L7 Ingress Controller & Subdomain Routing)
                   │
                   ▼
  hanzoai/gateway (JWT Auth, Quota/Rate Limiting, Identity Injection)
                   │
                   ▼
  hanzoai/cloud (The Unified "One Binary" Control Plane)
   ├─ IAM (hanzo.id) & KMS (kms.hanzo.ai)
   ├─ Model Hub (500+ LLMs, Routing, Prompting, RAG)
   ├─ Multi-Tenant BaaS (Base + Encrypted SQLite)
   ├─ Business Framework (DocType Engine on SQLite)
   ├─ Workflow Automation (Auto + Tasks over ZAP)
   ├─ Compute & Fleet Orchestrator (Visor + VM)
   ├─ Channel & Integration Registry (Slack, GitHub, Linear)
   ├─ Realtime ZAP Telemetry Ingestion (o11y Spans/Metrics/Logs)
   └─ In-Cluster BuildKit Job Dispatch (/v1/build)
                   │
    ┌──────────────┴──────────────┐
    ▼                             ▼
Sovereign Data Plane        hanzoai/egress
• Base (Multi-tenant BaaS)  (Outbound trust boundary:
• SQLite (SQLCipher 4)      credentials stay sealed in KMS,
• SQL (PostgreSQL DBMS)     metered external API calls,
• Datastore (ClickHouse)    and BYOK provider proxying)
• KV (In-Memory RESP/ZAP)
• S3 (S-Chain Object Store)
```

---

## The "Never Go Stale" Code Generation Pipeline (HIP-0139)

To ensure client libraries, documentation, CLI tools, and agent definitions never drift from production code, Hanzo enforces a **single-source-of-truth generation pipeline**:

```
Go Live Router (zap-proto/zip & hanzoai/cloud)
                   │
                   ▼
  make openapi ➔ GET /v1/openapi.json
  (Canonical 1,800+ path golden contract; verified by CI)
                   │
                   ▼
  hanzoai/openapi Generator (generate.py, sdks.yaml)
                   │
  ┌────────────────┼────────────────┬────────────────┐
  ▼                ▼                ▼                ▼
Rust CLI        MCP Server      Client SDKs       Documentation
(hanzoai/cli)   (hanzoai/mcp)   (14+ Languages)   (docs.hanzo.ai, llms.txt)
```

1. **Declared Once in Code**: Handlers, routes, request/response types, and security schemes are written once in Go using `zap-proto/zip`.
2. **Golden Contract Verification**: Running `make openapi` compiles the live route table into `openapi.yaml` and `private.yaml`. If an engineer edits a route or model without updating the golden spec, CI fails.
3. **Automated SDK & Tool Projection**: `hanzoai/openapi` automatically regenerates the Rust CLI, Model Context Protocol tools, and client SDKs across **14+ programming languages**, stamping each release with a cryptographic `.spec-lock`.

---

## Runtime Composition

### 1. Local Dev Runtime
* **Single Binary Footprint**: Run on a laptop with zero cloud dependencies.
* **CLI Entry**: `hanzo` CLI installed via `curl -fsSL https://hanzo.sh | sh`.
* **Local Cloud Server**: `hanzoai/cloud` runs unencrypted for development via `CLOUD_DEV_UNENCRYPTED=1 make build`.
* **Local BaaS**: `hanzoai/base` boots in-process on port `8090` using SQLite with immediate REST and realtime SSE change streams.
* **Local Inference**: `hanzoai/engine` serves quantized GGUF models on CPU, Apple Silicon Metal, or CUDA over `/v1/chat/completions`.
* **Coding Agents**: `hanzo dev` and `hanzoai/gen` run coding sessions locally within `hanzoai/kata` microVM sandboxes over standard I/O MCP.

### 2. Clustered Production Runtime
* **High-Availability Kubernetes**: Deployed across sovereign clusters (`hanzo-k8s`, `lux-k8s`, AWS EKS).
* **Identity Injection**: Edge requests pass through `gateway`, validating RSA-signed JWTs from `iam` and injecting trusted `X-User-Id` / `X-Org-Id` headers downstream.
* **Unified Control Plane**: `cloud` mounts all core subsystems dynamically using the `zip` framework without code divergence.
* **Sovereign GPU Inference**: Model routing passes through `hanzoai/ai` and `hanzo-inc/kai`, executing against resident `zenlm/zen` GPU nodes.
* **Continuous Delivery**: Reconciled continuously by Hanzo CD (`cd.hanzo.ai`, `hanzoai/deploy`) against declarative specs in `universe`.

### 3. Base Data Layer Composition
* **Multi-Tenant SQLite**: Each tenant/organization gets an isolated database at `/orgs/<org>/data.db`.
* **Zero Plaintext at Rest**: Encrypted via `hanzoai/sqlite` and SQLCipher 4 using keys derived from Hanzo KMS.
* **Streaming Replication**: Replicated in real time via `hanzoai/vfs` blocks to S-Chain object storage (`hanzoai/s3`).
* **In-Process JavaScript Hooks**: Business logic runs in sandboxed ECMAScript 5.1/6 VMs via Goja (`.base.js`).

### 4. Realtime Pipeline
* **Zero-Copy Protocol (ZAP)**: Binary communication over port `9653` and `/zap` WebSockets; 17x faster than standard JSON-RPC.
* **Reactive Database Streams**: Collection changes in Base immediately broadcast over Server-Sent Events (SSE).
* **Telemetry Streaming**: Node-local OpenTelemetry collectors stream spans, logs, and metrics directly to `apps/o11y` and Datastore.
* **Interactive Agent Sessions**: `hanzo dev` sessions stream live terminal PTY output, diff trees, and model reasoning to Mission Control.

### 5. Code Intelligence & Semantic Search Pipeline
* **Concrete Syntax Trees (AST)**: Parsed in-process via `hanzoai/ast` (Tree-sitter bindings for 40+ programming languages) into queryable s-expression CST nodes.
* **Language Server Protocol (LSP)**: `hanzoai/lsp` resolves cross-file definitions, type hierarchies, hover docs, and diagnostics without external IDE processes.
* **Trigram Inverted Index (tgram)**: `hanzoai/tgrep` builds 3-character sub-token posting lists across git repositories, providing sub-millisecond regex code search.
* **Semantic Vector & Graph Backend**: Code chunks are embedded and indexed via `hanzoai/vector` (HNSW) and linked to ontology nodes via `hanzoai/graph` (Dgraph engine over `luxfi/zapdb`), enabling hybrid semantic discovery at `POST /v1/semantic`.

### 6. App Platform & BuildKit PaaS
* **In-Cluster Multi-Arch BuildKit**: Invoked via `POST /v1/build` in `cloud`, dispatching isolated container builds with zero host Docker daemon exposure.
* **Ephemeral MicroVM Runners**: `POST /v1/runner` allocates just-in-time Kata microVMs (`hanzoai/git-runner`) for isolated code evaluation and test suites.
* **Artifact & Package Distribution**: Multi-arch container images and Helm charts push to `oci.hanzo.ai` (backed by `hanzoai/s3`), while language dependencies resolve via `pkg.hanzo.ai`.
* **Forge & Hanzo CD Reconciler**: Hanzo Forge (`forge.hanzo.ai` / `hanzoai/git`) hosts repositories, PRs, and Kanban project boards, while Hanzo CD (`cd.hanzo.ai` / `hanzoai/deploy`) continuously syncs declared Helm charts into production.

---

## Cryptography & Key Management: Split MPC & Hardware Security

Governed by [**HIP-0136: One Secret, One Path**](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0136-one-secret-one-path.md) and [**HIP-0409: KMS CRD**](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0409-kms-crd.md), **Hanzo KMS** (`kms.hanzo.ai`, [`hanzoai/kms`](https://github.com/hanzoai/kms)) is a thin, high-performance Go service layered over [`luxfi/kms`](https://github.com/luxfi/kms) and [`luxfi/mpc`](https://github.com/luxfi/mpc):

```
                       Hanzo KMS (kms.hanzo.ai)
                                  │
    ┌─────────────────────────────┼─────────────────────────────┐
    ▼                             ▼                             ▼
1. SPLIT MPC BACKEND        2. OPTIONAL HARDWARE HSM       3. ENVELOPE ENCRYPTION
Threshold Secret Sharing    Physical Security Modules     Local Hardware Accelerated
• FROST (Schnorr threshold) • PKCS#11 / YubiHSM           • AES-256-GCM / Poly1305
• CGGMP21 (ECDSA threshold) • AWS CloudHSM                • SQLCipher 4 At-Rest Engine
• Pulsar (Ring-LWE PQ)      • Google Cloud KMS / Azure    • Memory-only Grant Decryption
```

* **Split MPC Backend**: Private master keys never exist on a single machine. Key shares are computed and distributed across independent threshold nodes via **FROST** (Schnorr), **CGGMP21** (ECDSA), and **Pulsar** (Ring-LWE lattice post-quantum threshold signatures).
* **Optional Hardware HSM**: Enterprise deployments can bind root keys to dedicated hardware security modules via standard **PKCS#11**, **YubiHSM**, **AWS CloudHSM**, or cloud key vaults.
* **Post-Quantum Cryptography Suite**: Implements **ML-KEM-768** (Kyber key encapsulation), **ML-DSA-65** (Dilithium digital signatures), and **Pulsar** to protect data against store-now-decrypt-later nation-state adversaries.
* **Published Keys vs. Secret Keys**:
  * **Published Keys (Identity & Verification)**: Ed25519 and Secp256k1 public keys, DID documents (`did:hanzo:<org>:<user>`, [HIP-0097](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0097-sovereign-identity.md)), and public JWKS (`https://hanzo.id/.well-known/jwks.json`). Downstream clients and gateways verify tokens, signatures, and EIP-712 payment authorizations client-side with zero network roundtrips.
  * **Secret Keys (KMS Sealed Envelope)**: Sensitive credentials (provider API tokens, private keys, database master encryption keys) are sealed in Hanzo KMS under canonical paths `/orgs/{org}/users/{user}/connectors/{provider}/{label}`. They are never committed to git, written to disk, or injected as plain container environment variables.
* **KMS Environments & Zero-Plaintext Grants**:
  * `KMS_ENV=dev`: Allows local developers and offline testing to mock envelope grants in-memory without contacting an external HSM or MPC cluster.
  * `KMS_ENV=production`: Enforces hardware HSM and split-MPC quorum consensus. Workloads authenticate via Kubernetes ServiceAccount tokens; `secret.Boot` reads scoped secrets directly into RAM as memory-only grants.

---

## The Dual-Repo SDK Architecture

To ensure high performance across every ecosystem without code duplication, Hanzo employs a **dual-repository SDK model**:
* **Top-Level Discovery (`hanzoai/<lang>-sdk`)**: The canonical developer entrance, idiomatic wrappers, documentation, and package metadata.
* **True Implementation Home (`hanzo-<lang>/sdk`)**: The underlying native source code, toolchain-specific build configurations, and compiler pipelines generated directly from `api.hanzo.ai/v1/openapi.json` via [HIP-0139](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0139-capability.md).

| Language | Canonical Entry Repo | Implementation Home | Package Registry | Installation |
| :--- | :--- | :--- | :--- | :--- |
| **Python** | [**hanzoai/python-sdk**](https://github.com/hanzoai/python-sdk) | [**hanzo-py/sdk**](https://github.com/hanzo-py/sdk) | PyPI (`hanzoai`) | `pip install "hanzoai>=8"` |
| **TypeScript / JS**| [**hanzoai/js-sdk**](https://github.com/hanzoai/js-sdk) | [**hanzo-js/sdk**](https://github.com/hanzo-js/sdk) | npm (`hanzoai`, `@hanzo/ai`)| `npm i hanzoai` |
| **Go** | [**hanzoai/go-sdk**](https://github.com/hanzoai/go-sdk) | [**hanzo-go/sdk**](https://github.com/hanzo-go/sdk) | Go Modules | `go get github.com/hanzo-go/sdk` |
| **Rust** | [**hanzoai/rust-sdk**](https://github.com/hanzoai/rust-sdk) | [**hanzo-rs/sdk**](https://github.com/hanzo-rs/sdk) | crates.io (`hanzo`) | `cargo add hanzo` |
| **C++** | [**hanzoai/cpp-sdk**](https://github.com/hanzoai/cpp-sdk) | [**hanzo-cpp/sdk**](https://github.com/hanzo-cpp/sdk) | CMake / vcpkg | `#include <hanzo/client.hpp>` |
| **Swift** | [**hanzoai/swift-sdk**](https://github.com/hanzoai/swift-sdk) | [**hanzo-swift/sdk**](https://github.com/hanzo-swift/sdk) | Swift Package Manager | `.package(url: "...", ...)` |
| **Dart / Flutter**| [**hanzoai/dart-sdk**](https://github.com/hanzoai/dart-sdk) | [**hanzo-dart/sdk**](https://github.com/hanzo-dart/sdk) | pub.dev (`hanzo`) | `dart pub add hanzo` |
| **Kotlin** | [**hanzoai/kotlin-sdk**](https://github.com/hanzoai/kotlin-sdk) | [**hanzo-kt/sdk**](https://github.com/hanzo-kt/sdk) | Maven Central | `implementation("ai.hanzo:sdk")`|
| **Java** | [**hanzoai/java-sdk**](https://github.com/hanzoai/java-sdk) | [**hanzo-java/sdk**](https://github.com/hanzo-java/sdk) | Maven Central | `<groupId>ai.hanzo</groupId>` |
| **PHP** | [**hanzoai/php-sdk**](https://github.com/hanzoai/php-sdk) | [**hanzo-php/sdk**](https://github.com/hanzo-php/sdk) | Packagist (`hanzoai/sdk`) | `composer require hanzoai/sdk` |
| **Ruby** | [**hanzoai/ruby-sdk**](https://github.com/hanzoai/ruby-sdk) | [**hanzo-ruby/sdk**](https://github.com/hanzo-ruby/sdk) | RubyGems (`hanzoai`) | `gem install hanzoai` |
| **Common Lisp** | [**hanzo-cl**](https://github.com/hanzo-cl) | [**hanzo-cl/sdk**](https://github.com/hanzo-cl/sdk) | Quicklisp | `(ql:quickload :hanzo)` |

---

## The 70+ Hanzo GitHub Organizations

The Hanzo ecosystem is organized across specialized, purpose-driven GitHub organizations:

| Domain | Organizations | Primary Responsibility |
| :--- | :--- | :--- |
| **Core Platforms** | `hanzoai`, `hanzo-core`, `hanzohq`, `hanzo-labs`, `hanzoworks`, `hanzo-community` | Open-source platform cores, control plane, experimental labs, and community extensions |
| **Language SDKs** | `hanzo-py`, `hanzo-js`, `hanzo-go`, `hanzo-rs`, `hanzo-cpp`, `hanzo-swift`, `hanzo-dart`, `hanzo-kt`, `hanzo-kotlin`, `hanzo-java`, `hanzo-cl` | Native language SDK implementation repositories and package generators |
| **Identity & Security** | `hanzoiam`, `hanzoid`, `hanzokms`, `hanzompc`, `hanzozt` | Sovereign identity (`hanzo.id`), key custody (`kms.hanzo.ai`), MPC ceremonies, zero-trust overlay |
| **Data & Storage** | `hanzodb`, `hanzosql`, `hanzokv`, `hanzos3`, `hanzo-ds`, `hanzodocdb` | PostgreSQL engines, in-memory KV, S-Chain object store, ClickHouse OLAP, document DBs |
| **Models & Compute** | `hanzo-ml`, `hanzolm`, `hanzo-lm`, `hanzovm` | Zen model family weights, Rust tensor libraries, inference acceleration, virtualization |
| **Agents & Workflows**| `hanzo-studio`, `hanzobot`, `hanzoteam`, `hanzochat`, `hanzoskills`, `hanzoskill` | AI Studio, bot gateways (WhatsApp/Telegram), team workspaces, atomic skill discovery |
| **Client Applications**| `hanzoapp`, `hanzo-app`, `hanzo-apps` | Production web applications, user consoles, and client frontends |
| **UI & Styling** | `hanzoui`, `hanzogui` | Universal component library (`@hanzo/ui`) and optimizing style compiler (`@hanzo/gui`) |
| **DevOps & Delivery** | `hanzocd`, `hanzo-git`, `hanzocr`, `hanzodns`, `hanzo-templates`, `hanzo-os` | Continuous delivery (`cd.hanzo.ai`), Git Forge (`forge.hanzo.ai`), OCI registry (`oci.hanzo.ai`), DNS |
| **Telemetry & Signals**| `hanzoo11y`, `hanzolog`, `hanzometric`, `hanzomsg`, `hanzofn` | Observability pipelines over ZAP, metrics stores, pub/sub messaging, serverless functions |
| **Blockchain & Fi** | `hanzonet`, `hanzonetwork`, `hanzodao`, `hanzo-fi`, `hanzo-industries`, `hanzo-agency` | Hanzo validator network, consensus nodes, DeFi primitives, and specialized vertical solutions |
| **Documentation** | `hanzodocs`, `hanzo-docs` | Documentation sites, LLM context indexes, and OpenAPI specifications |
| **Enterprise Enclaves**| `hanzo-inc` | Proprietary cloud platform, private hardware kernels, and member-only enclaves |

---

## Master Repository Catalog (`hanzoai/*`)

### 1. Edge, Traffic, Security & Cloud Control Plane
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**ingress**](https://github.com/hanzoai/ingress) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1133](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1133-ingress-embedded-edge.md) | High-performance L4/L7 Ingress Controller & Reverse Proxy |
| [**gateway**](https://github.com/hanzoai/gateway) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1127](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1127-gateway-edge-policy.md) | API Gateway fronting `api.hanzo.ai` (JWT auth, rate limits, identity injection) |
| [**egress**](https://github.com/hanzoai/egress) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0143](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0143-egress-outbound-trust-boundary.md) | Outbound security boundary; meters external calls without leaking credentials |
| [**cloud**](https://github.com/hanzoai/cloud) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0106](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0106-hanzo-plugin-contract.md) | Flagship open-source unified Go backend ("The One Binary") |
| [**iam**](https://github.com/hanzoai/iam) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0111](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0111-iam-authentication-standard.md) | Sovereign Identity & Access Management service (`hanzo.id`) |
| [**kms**](https://github.com/hanzoai/kms) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0136](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0136-one-secret-one-path.md) | Sovereign Key Management Service & envelope encryption (`kms.hanzo.ai`) |

### 2. Multi-Cloud Compute, Sandboxes & Kubernetes Fleet
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**vm**](https://github.com/hanzoai/vm) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1172](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1172-visor-compute-you-rent.md) | Multi-cloud compute plane (AWS, GCP, Azure, DO, Bare-Metal) under `/v1/visor/*` |
| [**visor**](https://github.com/hanzoai/visor) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0123](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0123-visor-fleet-autoscaling.md) | Userspace gVisor application kernel & container sandbox runtime (`runsc`) |
| [**kata**](https://github.com/hanzoai/kata) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1146](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1146-sandbox-compute-primitive.md) | Hypervisor-isolated Kata Container microVM execution sandbox for agents |
| [**tasks**](https://github.com/hanzoai/tasks) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1062](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1062-tasks-the-durable-run.md) | Durable workflow execution engine & distributed task queue over ZAP |

### 3. Business Apps, Metadata Engine & ERP
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**framework**](https://github.com/hanzoai/framework) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1126](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1126-framework-doctype-engine.md) | Metadata-driven DocType engine in native Go on SQLite (zero Python runtime) |
| [**erp**](https://github.com/hanzoai/erp) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Sovereign Enterprise Resource Planning deployment (`erp.hanzo.ai`) |
| [**crm**](https://github.com/hanzo-inc/crm) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1120](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1120-crm-sales-pipeline.md) | AI-native sales and customer pipeline management (`crm.hanzo.ai`) |

### 4. Framework, RPC & Code Generation
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**zip**](https://github.com/zap-proto/zip) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0122](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0122-zip-zap-native-application-server.md) | Go web micro-framework (Fiber v3 / fasthttp) with native ZAP-typed handlers |
| [**zap**](https://github.com/zap-proto/zap) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0114](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0114-zap-inter-vm-cognitive-transport.md) | Zero-copy Application Protocol (ZAP) runtimes (Rust, Go, TypeScript) |
| [**openapi**](https://github.com/hanzoai/openapi) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0139](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0139-capability.md) | Single-source generator projecting `/v1/openapi.json` into 9 client surfaces |
| [**wasm2go**](https://github.com/hanzoai/wasm2go) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Ahead-of-time WebAssembly to Go / Go assembly (`amd64.s`, `arm64.s`) AOT compiler |

### 5. AI Compute, Models, Inference & Autonomous Agents
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**ai**](https://github.com/hanzoai/ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1211](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1211-ai-the-model-api.md) | AI control plane, model catalogue (500+ LLMs), RAG orchestrator |
| [**ml**](https://github.com/hanzoai/ml) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0109](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0109-hanzo-ml-cloud-toolkit.md) | Multi-backend Rust tensor & ML framework (`hanzo-ml`, CUDA, Metal, ROCm, Vulkan) |
| [**engine**](https://github.com/hanzoai/engine) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1124](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1124-engine-runtime-lens.md) | Standalone multimodal inference server (text, vision, audio, embeddings) |
| [**skills**](https://github.com/hanzoai/skills) | [hanzoskills.com](https://hanzoskills.com) | [HIP-1322](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1322-skills-the-discovery-catalogue.md) | 350+ atomic, progressive skills for Claude Code, Antigravity, and Hanzo Dev |
| [**agent**](https://github.com/hanzoai/agent) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1210](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1210-agents-define-run-keep.md) | Official Python Agent SDK (`pip install hanzo-agent`, imports as `agents`) |
| [**agents**](https://github.com/hanzoai/agents) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1210](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1210-agents-define-run-keep.md) | Multi-agent orchestration engine over Model Context Protocol (MCP) |
| [**personas**](https://github.com/hanzoai/personas) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0524](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0524-the-personal-agent.md) | Agent team roster, 1,044 historical & specialized figures, 67 expert personas |
| [**persona**](https://github.com/hanzoai/persona) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0524](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0524-the-personal-agent.md) | Multi-language persona profile loader and validator (Rust, TS, Python) |
| [**dev**](https://github.com/hanzoai/dev) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1330](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1330-dev-the-agent-loop.md) | Sovereign autonomous AI coding agent loop |
| [**gen**](https://github.com/hanzoai/gen) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Terminal coding agent harness (`hanzo dev` / `gen`) with native MCP integration |
| [**enso**](https://github.com/hanzoai/enso) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0510](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0510-enso-learned-router.md) | Learned multimodal router and CDP browser automation agent |

### 6. Automation, Marketplace & Connectors
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**auto**](https://github.com/hanzoai/auto) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1063](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1063-auto-flows-that-run-themselves.md) | Native Go workflow automation engine with embedded canvas (`auto.hanzo.ai`) |
| [**market**](https://github.com/hanzoai/market) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1137](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1137-marketplace-listings.md) | Sovereign decentralized marketplace for agents, apps & MCP tools (`hanzo.market`) |
| [**mcp**](https://github.com/hanzoai/mcp) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0300](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0300-unified-mcp.md) | Model Context Protocol servers for agent tooling (stdio and HTTP transports) |

### 7. Sovereign Data Plane & Storage
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**base**](https://github.com/hanzoai/base) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1104](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1104-base-hosted-backend.md) | Multi-tenant BaaS with encrypted per-org SQLite instances & realtime sync |
| [**sqlite**](https://github.com/hanzoai/sqlite) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0302](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0302-encrypted-sqlite-replication-standard.md) | Unified SQLite facade with hardware-accelerated SQLCipher 4 encryption |
| [**csqlite**](https://github.com/hanzoai/csqlite) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0302](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0302-encrypted-sqlite-replication-standard.md) | CGo binding for SQLCipher 4 |
| [**sql**](https://github.com/hanzoai/sql) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0402](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0402-sql-crd.md) | Sovereign PostgreSQL database management distribution |
| [**datastore**](https://github.com/hanzoai/datastore) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0401](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0401-datastore-crd.md) | OLAP analytics database (ClickHouse fork decoupled over S-Chain storage) |
| [**kv**](https://github.com/hanzoai/kv) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1324](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1324-kv-buckets-of-versioned-values.md) | In-memory key-value store (RESP2/3 + native ZAP binary protocol on port 9653) |
| [**s3**](https://github.com/hanzoai/s3) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1165](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1165-s3-buckets-and-objects.md) | "S-Chain" distributed object storage substrate (SeaweedFS fork) |
| [**orm**](https://github.com/hanzoai/orm) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Canonical ORM supporting document `Model[T]` and relational schema |
| [**vfs**](https://github.com/hanzoai/vfs) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0107](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0107-streaming-replication-over-vfs.md) | Content-addressed, PQ-encrypted block storage abstraction |

### 8. Code Intelligence, AST/LSP & Vector Search
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**ast**](https://github.com/hanzoai/ast) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0300](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0300-unified-mcp.md) | Tree-sitter AST parser generator & concrete syntax trees across 40+ grammars |
| [**lsp**](https://github.com/hanzoai/lsp) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Language Server Protocol server daemon (symbol definitions, references, diagnostics) |
| [**tgrep**](https://github.com/hanzoai/tgrep) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Trigram-indexed (tgram) regex search engine for sub-millisecond codebase grep |
| [**vector**](https://github.com/hanzoai/vector) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0401](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0401-datastore-crd.md) | HNSW vector database for high-dimensional embeddings and semantic search |
| [**graph**](https://github.com/hanzoai/graph) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Distributed GraphQL & graph database engine over `luxfi/zapdb` posting lists |

### 9. Frontend Substrate, Components & Workspace Apps
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**gui**](https://github.com/hanzoai/gui) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0504](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0504-unified-design-system.md) | Universal styling library & optimizing compiler (`@hanzo/gui`, `@hanzogui/core`) |
| [**ui**](https://github.com/hanzoai/ui) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0504](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0504-unified-design-system.md) | 157+ React UI component library on `@hanzo/tokens` for Web, Expo, and Tauri |
| [**app**](https://github.com/hanzoai/app) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0528](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0528-mods-the-app-sdk.md) | Modular workspace app SDK (`@hanzo/app`) and native mod themes (`@hanzo/mod`) |
| [**build**](https://github.com/hanzoai/build) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Standalone `<Builder host={...} />` app builder (`hanzo.build`) |
| [**chat**](https://github.com/hanzoai/chat) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Standalone multi-brand chat client (`hanzo.chat`) |
| [**desktop**](https://github.com/hanzoai/desktop) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Native cross-platform desktop application |
| [**mobile**](https://github.com/hanzoai/mobile) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Native iOS & Android application built on Expo SDK 57 |
| [**extension**](https://github.com/hanzoai/extension) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Browser extension (Chrome, Firefox, Safari) and IDE plugins |

### 10. Sovereign Cloud Applications & Admin
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**admin**](https://github.com/hanzoai/admin) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1320](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1320-admin-the-operator-console.md) | SuperAdmin console (`admin.hanzo.ai`) & live `/code` agent session monitor |
| [**pay**](https://github.com/hanzoai/pay) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1220](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1220-commerce-the-merchant-half.md) | Tenant-neutral embeddable checkout and payment UI (`@hanzoai/pay`) |
| [**analytics**](https://github.com/hanzoai/analytics) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1190](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1190-event-product-analytics.md) | Privacy-focused analytics platform (`analytics.hanzo.ai`) |
| [**insights**](https://github.com/hanzoai/insights) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Data exploration & product intelligence (`insights.hanzo.ai`) |
| [**studio**](https://github.com/hanzoai/studio) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0506](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0506-hanzo-studio-agentic-creative-runtime.md) | Agent creative studio & prompt workbench (`studio.hanzo.ai`) |
| [**social**](https://github.com/hanzoai/social) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1153](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1153-social-transport-publishing.md) | Multi-channel social publishing engine (`social.hanzo.ai`) |
| [**team**](https://github.com/hanzoai/team) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1048](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1048-team.md) | Sovereign team collaboration platform (`hanzo.team`) |
| [**bot**](https://github.com/hanzoai/bot) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1107](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1107-bot-runs-on-a-surface.md) | Multi-channel personal assistant gateway (`hanzo.bot`) |

### 11. Sovereign DevOps, Registries & Delivery Fleet
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**git**](https://github.com/hanzoai/git) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1328](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1328-forge-the-meta-code-host.md) | Hanzo Forge git server and GitHub overlay (`forge.hanzo.ai`) |
| [**ci**](https://github.com/hanzoai/ci) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Continuous Integration pipeline and reusable workflows |
| [**git-runner**](https://github.com/hanzoai/git-runner) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Ephemeral Kata Container CI job runner (`ci.hanzo.ai`) |
| [**deploy**](https://github.com/hanzoai/deploy) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1122](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1122-deploy-gitops-plane.md) | Hanzo CD sovereign continuous delivery reconciler (`cd.hanzo.ai`) |
| [**oci.hanzo.ai**](https://oci.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1165](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1165-s3-buckets-and-objects.md) | Sovereign OCI container image and Helm chart registry backed by S-Chain |
| [**pkg.hanzo.ai**](https://pkg.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Universal package registry & mirror (npm, PyPI, Go, Cargo, Maven) |

### 12. Blockchain Substrate & Proof of AI (PoAI)
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**node**](https://github.com/hanzoai/node) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1020](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1020-chain-registry.md) | Sovereign `hanzod` network node in Rust (Chain ID 36963) |
| [**luxfi/consensus**](https://github.com/luxfi/consensus) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0125](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0125-consensus-plugin-placement-platform.md) | Quasar consensus engine (Photon/Wave/Focus + PQ triple-mode) |
| [**luxfi/node**](https://github.com/luxfi/node) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1021](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1021-chain-rpc-door.md) | Go Lux node host |
| [**luxfi/mpc**](https://github.com/luxfi/mpc) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0413](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0413-mpc-crd.md) | Multi-party computation ceremony engine (FROST, CGGMP21, Pulsar) |
| [**lux-gpu/gpu**](https://github.com/lux-gpu/gpu) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | GPU C ABI v10 runtime & hardware plugin loader |
| [**lux-gpu/gpu-kernels**](https://github.com/lux-gpu/gpu-kernels) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Canonical CUDA, Metal, and WGSL compute shaders |
| [**luxfhe/torus**](https://github.com/luxfhe/torus) | [docs.hanzo.ai](https://docs.hanzo.ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | Torus FHE compiler (Python/MLIR ➔ GPU vtbl) |
| [**PoAI**](https://github.com/luxfi/standard) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0901](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0901-proof-of-ai-native-execution-proofs.md) | Proof of AI verification contracts (PoI, PoT, PoE, PoC) |

---

## Public Open-Source vs. Sovereign Enterprise Enclave (`hanzo-inc`)

Hanzo operates on a clean separation between **Open Source Foundation (`hanzoai/*`)** and **Enterprise Sovereign Fleet (`hanzo-inc/*`)**:

```
                       The Sovereign Developer Stack
                                     │
      ┌──────────────────────────────┴──────────────────────────────┐
      ▼                                                             ▼
1. PUBLIC OPEN-SOURCE (hanzoai/*)             2. ENTERPRISE HOSTED ENCLAVE (hanzo-inc/*)
Fork & Assemble Architecture                   Private Cloud Control Plane
• 100% Sovereign & Self-Hostable               • Proprietary C/C++ AOT via hanzoai/wasm2go
• Single-binary local dev (hanzoai/cloud)     • Bare-metal & GPU manager (apps/visor)
• BaaS data plane (hanzoai/base + SQLite)      • In-cluster BuildKit engine (apps/platform)
• Multi-tenant REST & ZAP streaming            • EIP-712 USDC crypto clearinghouse
• Open MCP tools (AST, LSP, tgrep, vector)     • Kai decision engine & calibration models
• Standard Docker & Helm deployments           • Hardware HSM & Quorum MPC consensus
```

* **Fork and Assemble Locally**: Developers can freely fork public repos, assemble their own backend or AI agent mesh on top of Hanzo's canonical `/v1/*` REST and ZAP binary endpoints, and deploy to their own infrastructure with zero external telemetry or cloud lock-in.
* **Enterprise Cloud Enclave**: The managed cloud fleet (`cloud.hanzo.ai`, `platform.hanzo.ai`) uses `wasm2go` to compile high-performance native kernels directly into Go assembly (`amd64.s`/`arm64.s`), eliminating CGo toolchains while providing high-throughput machine scheduling, JIT runner allocation, and hardware-attested enclave execution.

---

## Quickstart: Run Hanzo on Your Machine

### 1. Install the Sovereign CLI
```bash
curl -fsSL https://hanzo.sh | sh
hanzo auth login
```

### 2. Run Local BaaS (Base)
```bash
git clone https://github.com/hanzoai/base.git
cd base
go run ./examples/base serve
# Open http://127.0.0.1:8090/v1/
```

### 3. Run the Open AI Cloud (Single Binary)
```bash
docker run -d -p 8080:8080 \
  -e CLOUD_DEV_UNENCRYPTED=1 \
  -e CLOUD_LISTEN=0.0.0.0:8080 \
  ghcr.io/hanzoai/cloud:latest
# Open http://127.0.0.1:8080
```

### 4. Launch Local Coding Agent
```bash
hanzo dev
# Or with MCP:
gen --mcp
```

---

<p align="center">
  <strong>Hanzo AI, Inc. — Techstars '17</strong><br>
  Open Source under Apache-2.0 and MIT per <a href="https://github.com/hanzoai/hips/blob/main/HIPs/hip-0137-one-license.md">HIP-0137</a>.
</p>
