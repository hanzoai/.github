<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/hanzoai/.github/main/profile/logo-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/hanzoai/.github/main/profile/logo-light.svg">
    <img src="https://raw.githubusercontent.com/hanzoai/.github/main/profile/logo-dark.svg" alt="Hanzo" width="120">
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
  <a href="https://docs.hanzo.ai/docs/contributing"><strong>Contributing</strong></a> ·
  <a href="https://discord.gg/XthHQQj"><strong>Discord</strong></a> ·
  <a href="https://hanzo.ai/bounty"><strong>Bounties</strong></a> ·
  <a href="https://hips.hanzo.ai"><strong>HIPs</strong></a> ·
  <a href="https://hanzoskills.com"><strong>Skills</strong></a> ·
  <a href="https://docs.hanzo.ai/llms.txt"><strong>llms.txt</strong></a>
</p>

---

## Quickstart & Onboarding

```bash
npm i -g hanzo                 # install on any OS (or: curl -fsSL https://hanzo.sh | sh)
hanzo auth login               # sign in and mint an API key
hanzo dev                      # launch the terminal coding agent
npx -y hanzo mcp               # start the MCP server over stdio
```

| Path | Where to go |
| :--- | :--- |
| **Start building** | [Quickstart](https://docs.hanzo.ai/docs/quickstart) · [For Agents (`llms.txt`)](https://docs.hanzo.ai/docs/agents) · [Try Dev in Browser](https://hanzo.ai/dev) |
| **Contribute** | [Contributor Guide](https://docs.hanzo.ai/docs/contributing) · [Open Bounties](https://hanzo.ai/bounty) · [Leaderboard](https://hanzo.ai/leaderboard) |
| **Community** | [Join Hanzo Discord](https://discord.gg/XthHQQj) (`#docs` for docs feedback, `#hips` for proposals, `#general` for engineering) |
| **Specifications** | [Hanzo Improvement Proposals (HIPs)](https://hips.hanzo.ai) ([`hanzoai/hips`](https://github.com/hanzoai/hips)) |

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
  AWS Network Load Balancer (NLB)
                   │
                   ▼
  hanzoai/ingress (L4/L7 Ingress Controller, TLS Termination & Subdomain Routing)
                   │
                   ▼
  hanzoai/gateway (Stateless Gateway: JWT Auth, Quota/Rate Limiting, Identity Injection)
                   │
                   ▼
  hanzoai/cloud (Unified "One Binary" Control Plane — Lazy-Loads All /v1/* APIs)
   ├─ IAM (hanzo.id) & KMS (kms.hanzo.ai)
   ├─ Model Hub (500+ LLMs, Routing, Prompting, RAG)
   ├─ Multi-Tenant BaaS (Base + Encrypted SQLite)
   ├─ Headless Commerce & Billing (Crypto / Card / Wire Clearinghouse)
   ├─ Workflow Automation (Auto + Tasks over ZAP)
   ├─ Native Sandbox Orchestrator (Visor + VM over ZAP)
   ├─ Realtime ZAP Telemetry Ingestion (o11y Spans/Metrics/Logs)
   └─ In-Cluster BuildKit Job Dispatch (/v1/build)
                   │
    ┌──────────────┴────────────────────────────┐
    ▼                                           ▼
Sovereign Data Plane                     hanzoai/ai, Tasks & Agents
• Base (Multi-tenant BaaS)                      │
• SQLite (Hardware Encrypted)                   ▼ (Credential-Free Outbound Call)
• SQL (Relational Engine)                hanzoai/egress (Outbound Security Boundary)
• Datastore (Columnar OLAP Engine)              │ (Rate Limits, Redaction, Audit Spans)
• KV (In-Memory RESP/ZAP)                       ▼
• S3 (S-Chain Object Store)              Hanzo KMS & MPC Nodes
                                         (In-Flight Ephemeral Key Unwrapping / HSM)
                                                │
                                                ▼ (Egress Dispatch With Injected Auth)
                                         External Partner APIs & BYOK Providers
                                         (Model Providers, Payment Gateways, Webhooks)
```

<p align="center">
  <a href="https://github.com/hanzoai/ingress"><strong>hanzoai/ingress</strong></a> ➔
  <a href="https://github.com/hanzoai/gateway"><strong>hanzoai/gateway</strong></a> ➔
  <a href="https://github.com/hanzoai/cloud"><strong>hanzoai/cloud</strong></a> ➔
  <a href="https://github.com/hanzoai/ai"><strong>hanzoai/ai</strong></a> ➔
  <a href="https://github.com/hanzoai/egress"><strong>hanzoai/egress</strong></a> ➔
  <a href="https://github.com/hanzoai/kms"><strong>hanzoai/kms</strong></a> &amp;
  <a href="https://github.com/hanzoai/mpc"><strong>hanzoai/mpc</strong></a>
</p>

> [!NOTE]
> **Network Isolation**: Hanzo KMS, Split-MPC, and Egress operate in strictly segregated, isolated network enclaves for defense-in-depth security.

### Outbound Trust Boundary: `AI ➔ Egress ➔ KMS/MPC ➔ Third Party`
Governed by [**HIP-0143: Egress Outbound Trust Boundary**](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0143-egress-outbound-trust-boundary.md), Hanzo enforces a zero-leakage perimeter for all external network interactions:
1. **Credential-Free Internal Calls**: Internal services ([`hanzoai/ai`](https://github.com/hanzoai/ai), [`hanzoai/auto`](https://github.com/hanzoai/auto), [`hanzoai/tasks`](https://github.com/hanzoai/tasks), coding agents) never store or receive raw external API keys. Outbound requests reference only scoped credential identifiers (`credential_id`).
2. **Outbound Boundary Enforcement ([`hanzoai/egress`](https://github.com/hanzoai/egress))**: Network policies force all outbound traffic through the [`egress`](https://github.com/hanzoai/egress) proxy. `egress` evaluates organization rate limits, checks token balance tariffs, scrubs internal headers, and records tamper-evident audit spans.
3. **In-Flight Key Injection via Split-MPC**: [`hanzoai/egress`](https://github.com/hanzoai/egress) contacts [Hanzo KMS](https://kms.hanzo.ai) ([`hanzoai/kms`](https://github.com/hanzoai/kms), [`hanzoai/mpc`](https://github.com/hanzoai/mpc)). Quorum threshold shares (FROST/CGGMP21/Pulsar) or physical hardware HSMs unwrap the key in-flight, injecting the token directly into the outbound HTTP authorization header in RAM.
4. **External Dispatch**: Requests are dispatched over TLS to external providers. Credentials never touch disk, container environment variables, or model reasoning contexts, and responses stream directly back through [`egress`](https://github.com/hanzoai/egress).

---

## Deterministic Code Generation Pipeline (HIP-0139)

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

<p align="center">
  <a href="https://github.com/zap-proto/zip"><strong>zap-proto/zip</strong></a> &amp;
  <a href="https://github.com/hanzoai/cloud"><strong>hanzoai/cloud</strong></a> ➔
  <a href="https://github.com/hanzoai/openapi"><strong>hanzoai/openapi</strong></a> ➔
  <a href="https://github.com/hanzoai/cli"><strong>hanzoai/cli</strong></a> ·
  <a href="https://github.com/hanzoai/mcp"><strong>hanzoai/mcp</strong></a> ·
  <a href="https://docs.hanzo.ai"><strong>docs.hanzo.ai</strong></a>
</p>

1. **Declared Once in Code**: Handlers, routes, request/response types, and security schemes are written once in Go using [`zap-proto/zip`](https://github.com/zap-proto/zip).
2. **Golden Contract Verification**: Running `make openapi` compiles the live route table into `openapi.yaml` and `private.yaml`. If an engineer edits a route or model without updating the golden spec, CI fails.
3. **Automated SDK & Tool Projection**: [`hanzoai/openapi`](https://github.com/hanzoai/openapi) automatically regenerates the Rust CLI, Model Context Protocol tools, and client SDKs across **14+ programming languages**, stamping each release with a cryptographic `.spec-lock`.

---

## Runtime Composition

<details>
<summary><strong>Expand 12 Runtime Subsystems (Local Dev, Clustered Production, ORM, ZAP, Visor, AST/LSP, BuildKit, O11y, Commerce, Legal, AI Network, Multi-Tenant IAM)</strong></summary>

### 1. Local Dev Runtime
* **Single Binary Footprint**: Run on a laptop with zero cloud dependencies.
* **One-Command Boot (`hanzo up`)**: Boots the entire unified Hanzo cloud locally, lazy-loading each service (`/v1/*`) on-demand!
* **CLI Entry**: `hanzo` CLI installed via `curl -fsSL https://hanzo.sh | sh`. Login as a user or administrator with `hanzo auth login`.
* **Local Cloud Server**: [`hanzoai/cloud`](https://github.com/hanzoai/cloud) runs unencrypted for development via `CLOUD_DEV_UNENCRYPTED=1 make build`.
* **Local BaaS**: [`hanzoai/base`](https://github.com/hanzoai/base) boots in-process on port `8090` using SQLite with immediate REST and realtime SSE change streams.
* **Local Inference**: [`hanzoai/engine`](https://github.com/hanzoai/engine) serves quantized GGUF models on CPU, Apple Silicon Metal, or CUDA over `/v1/chat/completions`.
* **Coding Agents**: `hanzo dev` runs coding sessions locally within [`hanzoai/kata`](https://github.com/hanzoai/kata) microVM sandboxes over standard I/O MCP.

### 2. Clustered Production Runtime
* **High-Availability Kubernetes**: Deployed across sovereign clusters (`hanzo-k8s`, AWS EKS, etc).
* **Ingress & Identity Injection**: Requests pass through AWS Network Load Balancers (NLB), [`hanzoai/ingress`](https://github.com/hanzoai/ingress) (handling TLS termination and certificates), and stateless [`hanzoai/gateway`](https://github.com/hanzoai/gateway) (validating RSA-signed JWTs from `iam` and injecting trusted `X-User-Id` / `X-Org-Id` headers downstream).
* **Unified Control Plane**: [`hanzoai/cloud`](https://github.com/hanzoai/cloud) mounts all core subsystems dynamically using the [`zip`](https://github.com/zap-proto/zip) framework without code divergence.
* **Sovereign GPU Inference**: Model routing passes through [`hanzoai/ai`](https://github.com/hanzoai/ai) and [`hanzoai/kai`](https://github.com/hanzoai/kai), executing against resident [`hanzoai/engine`](https://github.com/hanzoai/engine) inference engine and [`hanzoai/ml`](https://github.com/hanzoai/ml) framework.
* **Continuous Delivery**: Reconciled continuously by Hanzo CD (`cd.hanzo.ai`, [`hanzoai/cd`](https://github.com/hanzoai/cd)) against declarative specs in [`hanzoai/deploy`](https://github.com/hanzoai/deploy).

### 3. Base Data Layer & Database-Agnostic ORM Composition
* **Database-Agnostic ORM ([`hanzoai/orm`](https://github.com/hanzoai/orm))**: Governed by [**HIP-0144: Where State Lives**](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0144-where-state-lives.md). The Hanzo data layer is completely agnostic of the underlying SQL storage engine:
  * **Fast Embedded Local Dev**: Defaults to SQLite (with SQLCipher 4 hardware encryption or in-memory) for instant, zero-dependency `hanzo up` boots without running external database containers.
  * **Pluggable Multi-Backend Drivers**: Seamlessly switches to external SQL engines — PostgreSQL wire protocol via [`hanzoai/sql`](https://github.com/hanzoai/sql), columnar OLAP via [`hanzoai/datastore`](https://github.com/hanzoai/datastore), MySQL, MariaDB, TiDB, and CockroachDB — with identical Go application code.
  * **Unified Type-Safe API**: Provides generic `Model[T]`, schema auto-migrations, transactional safety, and zero-allocation query building.
* **State Ranks (HIP-0144)**:
  * **Rank 1 (Per-Tenant File)**: [`hanzoai/base`](https://github.com/hanzoai/base) provisions isolated, per-org SQLite databases (`/orgs/<org>/data.db`) encrypted with organization-specific SQLCipher 4 keys derived from Hanzo KMS.
  * **Rank 2 (Column Store)**: [`hanzoai/datastore`](https://github.com/hanzoai/datastore) ingests high-throughput telemetry, analytics, and event streams decoupled over S-Chain object storage ([`hanzoai/s3`](https://github.com/hanzoai/s3)).
  * **Rank 3 (Shared SQL & KV)**: [`hanzoai/sql`](https://github.com/hanzoai/sql) and [`hanzoai/kv`](https://github.com/hanzoai/kv) provide shared clustered relational state and in-memory caches where multi-tenant concurrency requires a centralized server.
* **Streaming Replication**: Replicated in real time via [`hanzoai/vfs`](https://github.com/hanzoai/vfs) blocks to S-Chain distributed object storage ([`hanzoai/s3`](https://github.com/hanzoai/s3)).
* **In-Process JavaScript Hooks**: Business logic runs in sandboxed ECMAScript VMs via Goja (`.base.js`).

### 4. Realtime Pipeline
* **Zero-Copy Protocol (ZAP)**: Binary communication over port `9653` and `/zap` WebSockets; 17x faster than standard JSON-RPC.
* **Reactive Database Streams**: Collection changes in Base immediately broadcast over Server-Sent Events (SSE).
* **Telemetry Streaming**: Node-local OpenTelemetry collectors stream spans, logs, and metrics directly to `apps/o11y` and Datastore.
* **Interactive Agent Sessions**: `hanzo dev` sessions stream live terminal PTY output, diff trees, and model reasoning to Mission Control.

### 5. Native Sandboxing & Visor Runtime
* **Native Userspace Sandbox ([`hanzoai/visor`](https://github.com/hanzoai/visor))**: Lightweight application kernel and container sandbox written in Go, communicating natively over the zero-copy ZAP binary protocol instead of gRPC.
* **Low Latency & High Density**: Delivers sub-millisecond cold starts and significantly lower memory footprints than hypervisors (such as Firecracker), providing the high-density isolation necessary for agent fleets.
* **PaaS & Execution Primitives**: Directly powers ephemeral runner dispatch (`POST /v1/runner`), interactive coding sessions (`hanzo dev`), and code evaluation sandboxes.

### 6. Code Intelligence & Semantic Search Pipeline
* **Concrete Syntax Trees (AST)**: Parsed in-process via [`hanzoai/ast`](https://github.com/hanzoai/ast) (grammar parser generator across 40+ programming languages) into queryable s-expression CST nodes.
* **Language Server Protocol (LSP)**: [`hanzoai/lsp`](https://github.com/hanzoai/lsp) resolves cross-file definitions, type hierarchies, hover docs, and diagnostics without external IDE processes.
* **Trigram Inverted Index (tgram)**: [`hanzoai/tgrep`](https://github.com/hanzoai/tgrep) builds 3-character sub-token posting lists across git repositories, providing sub-millisecond regex code search.
* **Semantic Vector & Graph Backend**: Code chunks are embedded and indexed via [`hanzoai/vector`](https://github.com/hanzoai/vector) (HNSW) and linked to ontology nodes via [`hanzoai/graph`](https://github.com/hanzoai/graph) (distributed graph engine over [`luxfi/zapdb`](https://github.com/luxfi/zapdb)), enabling hybrid semantic discovery at `POST /v1/semantic`.

### 7. App Platform & BuildKit PaaS
* **In-Cluster Multi-Arch BuildKit**: Invoked via `POST /v1/build` in [`hanzoai/cloud`](https://github.com/hanzoai/cloud), dispatching isolated container builds with zero host Docker daemon exposure.
* **Ephemeral MicroVM Runners**: `POST /v1/runner` allocates just-in-time microVMs ([`hanzoai/git-runner`](https://github.com/hanzoai/git-runner)) for isolated code evaluation and test suites.
* **Artifact & Package Distribution**: Multi-arch container images and Helm charts push to `oci.hanzo.ai` (backed by [`hanzoai/s3`](https://github.com/hanzoai/s3)), while language dependencies resolve via `pkg.hanzo.ai`.
* **Forge & Hanzo CD Reconciler**: Hanzo Forge (`forge.hanzo.ai` / [`hanzoai/git`](https://github.com/hanzoai/git)) hosts repositories, PRs, and Kanban project boards, while Hanzo CD (`cd.hanzo.ai` / [`hanzoai/deploy`](https://github.com/hanzoai/deploy)) continuously syncs declared Helm charts into production.

### 8. Telemetry, Exception Tracking & Event Substrate
* **Native Exception Tracking ([`hanzoai/sentinel`](https://github.com/hanzoai/sentinel))**: Ingests standard error envelope protocols (`/api/{project_id}/envelope/`, `/api/{project_id}/store/`) from client SDKs with zero code modifications, providing crash capture and stack-frame unwinding (`ghcr.io/hanzoai/sentry`).
* **High-Throughput Event Ingestion (`POST /v1/event`)**: High-throughput clickstream and telemetry ingestion via lightweight, cookieless `tag.js` auto-capture.
* **Web & Product Analytics (`analytics.hanzo.ai`)**: Real-time traffic, page views, bounce rates, and referrer metrics respecting strict sovereign privacy and zero third-party cookie leakage.
* **Business Intelligence & OLAP Warehouse (`insights.hanzo.ai` & [`hanzoai/datastore`](https://github.com/hanzoai/datastore))**: Columnar OLAP engine decoupled over S-Chain object store ([`hanzoai/s3`](https://github.com/hanzoai/s3)). Powers arbitrary SQL aggregations, retention cohorts, conversion funnels, and revenue attribution.
* **Event Streaming & Protocol Adapters**: In-memory and persisted event pub/sub via [`hanzoai/pubsub`](https://github.com/hanzoai/pubsub) over ZAP binary transport (port `9653`), with zero-code protocol bridges for Kafka ([`hanzoai/kafka`](https://github.com/hanzoai/kafka)) and AMQP message queues ([`hanzoai/amqp`](https://github.com/hanzoai/amqp)).

### 9. Autonomous Headless Agentic Commerce, Billing & Treasury
* **Sovereign Commerce Engine ([`hanzoai/commerce`](https://github.com/hanzoai/commerce))**: Governed by [**HIP-1220**](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1220-commerce-the-merchant-half.md). Built on Hanzo's foundational commerce, analytics, and billing platform.
* **Headless Agent Provisioning**: Fully optimized for autonomous AI agents. Any agent can programmatically provision an organization, generate an API key, test on the free tier, and autonomously top up compute credits via native cryptocurrency (EIP-712 USDC / native MPC treasury rails), saved payment cards, or bank wires.
* **Customer Billing & Metering ([`hanzoai/billing`](https://github.com/hanzoai/billing))**: Real-time spend tracking, balance ledgers, usage metering (`/v1/usage`, [HIP-1313](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1313-usage-the-metered-record.md)), and customer billing portal (`billing.hanzo.ai`).
* **Financial AI & Treasury Rails ([`hanzoai/treasury`](https://github.com/hanzoai/treasury), [`hanzoai/ledger`](https://github.com/hanzoai/ledger))**: Governed by [**HIP-1001**](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1001-ledger-double-entry-ledger.md) and [**HIP-1221**](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1221-treasury-the-reserve-fund.md). Multi-tenant double-entry accounting ledger (`ledger`), bank clearinghouse connections, automated payment routing, and financial reconciliation.
* **Multi-Chain Key Custody & Wallet ([`hanzoai/wallet`](https://github.com/hanzoai/wallet))**: Governed by [**HIP-1161**](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1161-wallet-key-custody.md). Multi-chain SIWx signature verification, automated agent clearinghouse, and secure key custody.

### 10. Corporate Legal, Capital Rails & Document Security
* **Sovereign Equity & Cap Table Management ([`hanzoai/captable`](https://github.com/hanzoai/captable))**: Governed by [**HIP-1111**](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1111-captable.md). Sovereign equity, share classes, option pools, stakeholder ledgers, and automated vesting schedules (`captable.hanzo.ai`).
* **Cryptographic Tamper-Evident E-Signatures ([`hanzoai/esign`](https://github.com/hanzoai/esign))**: Governed by [**HIP-1125**](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1125-esign-signatures.md). Self-hosted document e-signature platform with verifiable digital audit trails, hash proofs, and field placement (`esign.hanzo.ai`).
* **Secure Virtual Data Rooms ([`hanzoai/dataroom`](https://github.com/hanzoai/dataroom))**: Governed by [**HIP-1121**](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1121-dataroom-shared-documents.md). Encrypted document sharing with dynamic viewer watermarking, role-based granular access revocation, and tamper-evident audit logs (`dataroom.hanzo.ai`).

### 11. AI Substrate & Decentralized AI Network (Phase 1 ➔ Phase 2)
* **Core ML Framework ([`hanzoai/ml`](https://github.com/hanzoai/ml))**: Multi-backend Rust tensor computation and machine learning toolkit (`hanzo-ml`, CUDA, Metal, ROCm, Vulkan).
* **LLM Inference Server ([`hanzoai/engine`](https://github.com/hanzoai/engine))**: High-performance multimodal inference server supporting GGUF, CUDA, Metal, and ISQ quantization over `/v1/chat/completions`.
* **Sovereign Node & P2P AI Mesh ([`hanzoai/node`](https://github.com/hanzoai/node))**: Blockchain node embedding the inference engine, shipped with the Hanzo desktop app to mine AI and connect local compute with cloud inference — paving the way for a global decentralized AI network for distributed training, inference, and a P2P compute marketplace.

### 12. Multi-Tenant Organizations, Unified IAM & Sandboxed Extensibility
* **Sovereign Identity Protocol (`did:hanzo:<org>:<user>`)**: Governed by [HIP-0097](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0097-clean-node-identity-did-hanzo-name.md) and `@hanzo/iam` (`hanzo.id`). Cryptographic user authentication, organization membership, and RBAC via RSA/ECDSA-signed JWT claims.
* **Per-Tenant Data & Key Isolation**: Every organization gets an independent SQLite database at `/orgs/<org>/data.db` encrypted with organization-specific SQLCipher 4 keys derived from Hanzo KMS, coupled with isolated ZAP pub/sub topic trees.
* **Frontend Runtime Customization**: Developers customize application look and feel dynamically using mod themes (`@hanzo/mod`), `@hanzo/ui`, and `@hanzo/design` tokens without rebuilding or recompiling frontend distributions.
* **Backend In-Process Sandboxes**: Users write custom business logic and backend extensions that execute safely in sandboxed environments:
  * **ECMAScript/JS Sandboxes**: Fast execution via Goja/V8 (`.base.js`) hooks for record lifecycle events and REST API extensions.
  * **WebAssembly Sandboxes**: Multi-language extensions compiled to Wasm running inside `wasm` runtimes and isolated `kata` microVM sandboxes.
* **Enterprise High-Performance `wasm2go` AOT**: In enterprise production, performance-critical Wasm modules are compiled directly into native Go assembly (`amd64.s`/`arm64.s`) via [`hanzoai/wasm2go`](https://github.com/hanzoai/wasm2go), running natively inside the "One Binary" with zero CGo overhead and zero interpreter tax.

</details>

---

## Cryptography & Key Management: Split MPC & Hardware Security

Governed by [**HIP-0136: One Secret, One Path**](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0136-one-secret-one-path.md) and [**HIP-0409: KMS CRD**](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0409-kms-crd.md), **Hanzo KMS** (`kms.hanzo.ai`, [`hanzoai/kms`](https://github.com/hanzoai/kms)) is a thin, high-performance Go service layered over [`hanzoai/mpc`](https://github.com/hanzoai/mpc):

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
  * **Published Keys (Identity & Verification)**: Ed25519 and Secp256k1 public keys, DID documents (`did:hanzo:<org>:<user>`, [HIP-0097](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0097-clean-node-identity-did-hanzo-name.md)), and public JWKS (`https://hanzo.id/.well-known/jwks.json`). Downstream clients and gateways verify tokens, signatures, and EIP-712 payment authorizations client-side with zero network roundtrips.
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
| **Java** | [**hanzoai/java-sdk**](https://github.com/hanzoai/java-sdk) | [**hanzo-java/sdk**](https://github.com/hanzo-java/sdk) | Maven Central (`ai.hanzo:hanzo-java-cloud`) | `implementation("ai.hanzo:hanzo-java-cloud")` |
| **C# / .NET** | [**hanzoai/csharp-sdk**](https://github.com/hanzoai/csharp-sdk) | [**hanzo-csharp/sdk**](https://github.com/hanzo-csharp/sdk) | NuGet (`Hanzo`) | `dotnet add package Hanzo` |
| **PHP** | [**hanzoai/php-sdk**](https://github.com/hanzoai/php-sdk) | [**hanzo-php/sdk**](https://github.com/hanzo-php/sdk) | Packagist (`hanzoai/sdk`) | `composer require hanzoai/sdk` |
| **Ruby** | [**hanzoai/ruby-sdk**](https://github.com/hanzoai/ruby-sdk) | [**hanzo-ruby/sdk**](https://github.com/hanzo-ruby/sdk) | RubyGems (`hanzoai`) | `gem install hanzoai` |
| **Common Lisp** | [**hanzo-cl**](https://github.com/hanzo-cl) | [**hanzo-cl/sdk**](https://github.com/hanzo-cl/sdk) | Quicklisp | `(ql:quickload :hanzo)` |

---

## The 70+ Hanzo GitHub Organizations

<details>
<summary><strong>Expand Organization Directory (Core, SDKs, IAM/KMS, Data, Models, Agents, Apps, UI, DevOps, Telemetry, Chain, Docs)</strong></summary>

The Hanzo ecosystem is organized across specialized, purpose-driven GitHub organizations:

| Domain | Organizations | Primary Responsibility |
| :--- | :--- | :--- |
| **Core Platforms** | [`hanzoai`](https://github.com/hanzoai), [`hanzo-core`](https://github.com/hanzo-core), [`hanzohq`](https://github.com/hanzohq), [`hanzo-labs`](https://github.com/hanzo-labs), [`hanzoworks`](https://github.com/hanzoworks), [`hanzo-community`](https://github.com/hanzo-community) | Open-source platform cores, control plane, experimental labs, and community extensions |
| **Language SDKs** | [`hanzo-py`](https://github.com/hanzo-py), [`hanzo-js`](https://github.com/hanzo-js), [`hanzo-go`](https://github.com/hanzo-go), [`hanzo-rs`](https://github.com/hanzo-rs), [`hanzo-cpp`](https://github.com/hanzo-cpp), [`hanzo-swift`](https://github.com/hanzo-swift), [`hanzo-dart`](https://github.com/hanzo-dart), [`hanzo-kt`](https://github.com/hanzo-kt), [`hanzo-kotlin`](https://github.com/hanzo-kotlin), [`hanzo-java`](https://github.com/hanzo-java), [`hanzo-cl`](https://github.com/hanzo-cl) | Native language SDK implementation repositories and package generators |
| **Identity & Security** | [`hanzoiam`](https://github.com/hanzoiam), [`hanzoid`](https://github.com/hanzoid), [`hanzokms`](https://github.com/hanzokms), [`hanzompc`](https://github.com/hanzompc), [`hanzozt`](https://github.com/hanzozt) | Sovereign identity (`hanzo.id`), key custody (`kms.hanzo.ai`), MPC ceremonies, zero-trust overlay |
| **Data & Storage** | [`hanzodb`](https://github.com/hanzodb), [`hanzosql`](https://github.com/hanzosql), [`hanzokv`](https://github.com/hanzokv), [`hanzos3`](https://github.com/hanzos3), [`hanzo-ds`](https://github.com/hanzo-ds), [`hanzodocdb`](https://github.com/hanzodocdb) | Relational SQL engines, in-memory KV, S-Chain object store, Columnar OLAP warehouse, document DBs |
| **Models & Compute** | [`hanzo-ml`](https://github.com/hanzo-ml), [`hanzolm`](https://github.com/hanzolm), [`hanzo-lm`](https://github.com/hanzo-lm), [`hanzovm`](https://github.com/hanzovm) | Zen model family weights, Rust tensor libraries, inference acceleration, virtualization |
| **Agents & Workflows**| [`hanzo-studio`](https://github.com/hanzo-studio), [`hanzobot`](https://github.com/hanzobot), [`hanzoteam`](https://github.com/hanzoteam), [`hanzochat`](https://github.com/hanzochat), [`hanzoskills`](https://github.com/hanzoskills), [`hanzoskill`](https://github.com/hanzoskill) | AI Studio, bot gateways (WhatsApp/Telegram), team workspaces, atomic skill discovery |
| **Client Applications**| [`hanzoapp`](https://github.com/hanzoapp), [`hanzo-app`](https://github.com/hanzo-app), [`hanzo-apps`](https://github.com/hanzo-apps) | Production web applications, user consoles, and client frontends |
| **UI & Styling** | [`hanzoui`](https://github.com/hanzoui), [`hanzogui`](https://github.com/hanzogui) | Universal component library (`@hanzo/ui`) and optimizing style compiler (`@hanzo/gui`) |
| **DevOps & Delivery** | [`hanzocd`](https://github.com/hanzocd), [`hanzo-git`](https://github.com/hanzo-git), [`hanzocr`](https://github.com/hanzocr), [`hanzodns`](https://github.com/hanzodns), [`hanzo-templates`](https://github.com/hanzo-templates), [`hanzo-os`](https://github.com/hanzo-os) | Continuous delivery (`cd.hanzo.ai`), Git Forge (`forge.hanzo.ai`), OCI registry (`oci.hanzo.ai`), DNS |
| **Telemetry & Signals**| [`hanzoo11y`](https://github.com/hanzoo11y), [`hanzolog`](https://github.com/hanzolog), [`hanzometric`](https://github.com/hanzometric), [`hanzomsg`](https://github.com/hanzomsg), [`hanzofn`](https://github.com/hanzofn) | Observability pipelines over ZAP, metrics stores, pub/sub messaging, serverless functions |
| **Blockchain & Fi** | [`hanzonet`](https://github.com/hanzonet), [`hanzonetwork`](https://github.com/hanzonetwork), [`hanzodao`](https://github.com/hanzodao), [`hanzo-fi`](https://github.com/hanzo-fi), [`hanzo-industries`](https://github.com/hanzo-industries), [`hanzo-agency`](https://github.com/hanzo-agency) | Hanzo validator network, consensus nodes, DeFi primitives, and specialized vertical solutions |
| **Documentation** | [`hanzodocs`](https://github.com/hanzodocs), [`hanzo-docs`](https://github.com/hanzo-docs) | Documentation sites, LLM context indexes, and OpenAPI specifications |
| **Enterprise Enclaves**| [`hanzo-enterprise`](https://github.com/hanzo-enterprise) | Proprietary cloud platform, private hardware kernels, and member-only enclaves |

</details>

---

## Master Repository Catalog (`hanzoai/*`)

<details>
<summary><strong>Expand Full Repository Catalog across 13 Architecture Domains</strong></summary>

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
| [**compute**](https://github.com/hanzoai/compute) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1172](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1172-visor-compute-you-rent.md) | Multi-cloud bare-metal, machine, and GPU cluster orchestration fleet |
| [**visor**](https://github.com/hanzoai/visor) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0123](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0123-visor-fleet-autoscaling.md) | Native userspace application kernel & container sandbox runtime in Go over ZAP |
| [**kata**](https://github.com/hanzoai/kata) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1146](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1146-sandbox-compute-primitive.md) | Hypervisor-isolated Kata Container microVM execution sandbox for agents |
| [**tasks**](https://github.com/hanzoai/tasks) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1062](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1062-tasks-the-durable-run.md) | Durable workflow execution engine & distributed task queue over ZAP |
| [**functions**](https://github.com/hanzoai/functions) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0060](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0060-serverless-functions-standard.md) | Serverless FaaS control plane & runtime on Wasm and V8 (`/v1/functions`) |

### 3. Business Apps, Metadata Engine & ERP
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**framework**](https://github.com/hanzoai/framework) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1126](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1126-framework-doctype-engine.md) | Metadata-driven DocType engine in native Go on SQLite (zero Python runtime) |
| [**erp**](https://github.com/hanzoai/erp) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1126](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1126-framework-doctype-engine.md) | Sovereign Enterprise Resource Planning deployment (`erp.hanzo.ai`) |
| [**crm**](https://github.com/hanzoai/crm) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1120](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1120-crm-sales-pipeline.md) | AI-native sales and customer pipeline management (`crm.hanzo.ai`) |

### 4. Framework, RPC & Code Generation
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**zip**](https://github.com/zap-proto/zip) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0122](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0122-zip-zap-native-application-server.md) | Go web application server and router with native ZAP-typed handlers and zero-allocation dispatch |
| [**zap**](https://github.com/zap-proto/zap) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0114](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0114-zap-inter-vm-cognitive-transport.md) | Zero-copy Application Protocol (ZAP) runtimes (Rust, Go, TypeScript) |
| [**openapi**](https://github.com/hanzoai/openapi) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0139](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0139-capability.md) | Single-source generator projecting `/v1/openapi.json` into 9 client surfaces |
| [**wasm2go**](https://github.com/hanzoai/wasm2go) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0127](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0127-v8-architecture-distribution-language-seam.md) | Ahead-of-time WebAssembly to Go / Go assembly (`amd64.s`, `arm64.s`) AOT compiler |

### 5. AI Compute, Models, Inference & Autonomous Agents
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**ai**](https://github.com/hanzoai/ai) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1211](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1211-ai-the-model-api.md) | AI control plane, model catalogue (500+ LLMs), RAG orchestrator |
| [**ml**](https://github.com/hanzoai/ml) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0109](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0109-hanzo-ml-cloud-toolkit.md) | Multi-backend Rust tensor & ML framework (`hanzo-ml`, CUDA, Metal, ROCm, Vulkan) |
| [**engine**](https://github.com/hanzoai/engine) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1124](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1124-engine-runtime-lens.md) | Standalone multimodal inference server (text, vision, audio, embeddings) |
| [**zen**](https://github.com/hanzoai/zen) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0096](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0096-ai-compute-contribution-rewards.md) | Zen open model family weights & optimized inference serving runtime |
| [**skills**](https://github.com/hanzoai/skills) | [hanzoskills.com](https://hanzoskills.com) | [HIP-1322](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1322-skills-the-discovery-catalogue.md) | 350+ atomic, progressive skills for Claude Code, Antigravity, and Hanzo Dev |
| [**catalog**](https://github.com/hanzoai/catalog) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1112](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1112-catalog.md) | Edge-cached public catalog serving models, pricing, and plan tiers |
| [**agent**](https://github.com/hanzoai/agent) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1210](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1210-agents-define-run-keep.md) | Official Python Agent SDK (`pip install hanzo-agent`, imports as `agents`) |
| [**agents**](https://github.com/hanzoai/agents) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1210](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1210-agents-define-run-keep.md) | Multi-agent orchestration engine over Model Context Protocol (MCP) |
| [**personas**](https://github.com/hanzoai/personas) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0524](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0524-the-personal-agent.md) | Agent team roster, 1,044 historical & specialized figures, 67 expert personas |
| [**persona**](https://github.com/hanzoai/persona) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0524](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0524-the-personal-agent.md) | Multi-language persona profile loader and validator (Rust, TS, Python) |
| [**dev**](https://github.com/hanzoai/dev) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1330](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1330-dev-the-agent-loop.md) | Sovereign autonomous AI coding agent loop |
| [**gen**](https://github.com/hanzoai/gen) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1212](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1212-exec-the-code-interpreter.md) | Terminal coding agent harness (`hanzo dev` / `gen`) with native MCP integration |
| [**enso**](https://github.com/hanzoai/enso) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0510](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0510-enso-learned-router.md) | Learned multimodal router and CDP browser automation agent |

### 6. Automation, Marketplace & Connectors
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**auto**](https://github.com/hanzoai/auto) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1063](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1063-auto-flows-that-run-themselves.md) | Native Go workflow automation engine with embedded canvas (`auto.hanzo.ai`) |
| [**flow**](https://github.com/hanzoai/flow) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1063](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1063-auto-flows-that-run-themselves.md) | Visual drag-and-drop AI workflow builder & agent node canvas |
| [**market**](https://github.com/hanzoai/market) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1137](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1137-marketplace-listings.md) | Sovereign decentralized marketplace for agents, apps & MCP tools (`hanzo.market`) |
| [**mcp**](https://github.com/hanzoai/mcp) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0300](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0300-unified-mcp.md) | Model Context Protocol servers for agent tooling (stdio and HTTP transports) |
| [**tools**](https://github.com/hanzoai/tools) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0300](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0300-unified-mcp.md) | Unified agent tools registry (shell, search, file, browser) in Rust |

### 7. Sovereign Data Plane & Storage
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**base**](https://github.com/hanzoai/base) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1104](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1104-base-hosted-backend.md) | Multi-tenant BaaS with isolated per-org SQLite instances (HIP-0144 Rank 1 state) & realtime SSE sync |
| [**sqlite**](https://github.com/hanzoai/sqlite) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0302](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0302-encrypted-sqlite-replication-standard.md) | Unified SQLite facade with hardware SQLCipher 4 encryption for fast embedded local dev |
| [**csqlite**](https://github.com/hanzoai/csqlite) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0302](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0302-encrypted-sqlite-replication-standard.md) | CGo binding for SQLCipher 4 |
| [**sql**](https://github.com/hanzoai/sql) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0402](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0402-sql-crd.md) | Clustered relational SQL engine (PostgreSQL wire protocol) for shared Rank 3 state |
| [**datastore**](https://github.com/hanzoai/datastore) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0401](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0401-datastore-crd.md) | High-throughput columnar OLAP analytics database (HIP-0144 Rank 2 state) decoupled over S-Chain |
| [**kv**](https://github.com/hanzoai/kv) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1324](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1324-kv-buckets-of-versioned-values.md) | In-memory key-value store (RESP2/3 + native ZAP binary protocol on port 9653) |
| [**pubsub**](https://github.com/hanzoai/pubsub) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1060](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1060-pubsub-the-tenant-door-on-the-bus.md) | Native event streaming & pub/sub broker over zero-copy ZAP binary transport |
| [**kafka**](https://github.com/hanzoai/kafka) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1323](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1323-kafka-the-wire-every-client-speaks.md) | Kafka wire protocol compatibility adapter for Hanzo streaming |
| [**amqp**](https://github.com/hanzoai/amqp) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1326](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1326-amqp-exchanges-queues-and-bindings.md) | AMQP 0-9-1 / 1.0 message broker adapter for enterprise queues |
| [**mq**](https://github.com/hanzoai/mq) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1326](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1326-amqp-exchanges-queues-and-bindings.md) | Distributed message & job queue built on Hanzo KV (Valkey/Redis compatible) |
| [**s3**](https://github.com/hanzoai/s3) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1165](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1165-s3-buckets-and-objects.md) | "S-Chain" distributed, content-addressed object storage substrate |
| [**orm**](https://github.com/hanzoai/orm) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0144](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0144-where-state-lives.md) | Database-agnostic Go ORM (SQLite for fast embedded local dev; supports PostgreSQL, Datastore, MySQL) with `Model[T]` |
| [**vfs**](https://github.com/hanzoai/vfs) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0107](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0107-streaming-replication-over-vfs.md) | Content-addressed, PQ-encrypted block storage abstraction |

### 8. Code Intelligence, AST/LSP & Vector Search
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**ast**](https://github.com/hanzoai/ast) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0300](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0300-unified-mcp.md) | Concrete syntax tree parser generator across 40+ programming languages |
| [**lsp**](https://github.com/hanzoai/lsp) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1214](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1214-lsp-live-code-intelligence.md) | Language Server Protocol server daemon (symbol definitions, references, diagnostics) |
| [**tgrep**](https://github.com/hanzoai/tgrep) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1114](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1114-code.md) | Trigram-indexed (tgram) regex search engine for sub-millisecond codebase grep |
| [**search**](https://github.com/hanzoai/search) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1147](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1147-search-hybrid-retrieval.md) | Hybrid lexical and semantic search engine (`POST /v1/search`) |
| [**index**](https://github.com/hanzoai/index) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1132](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1132-index-search.md) | High-throughput search index speaking the Meilisearch REST dialect |
| [**crawl**](https://github.com/hanzoai/crawl) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1117](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1117-crawl.md) | Web page reader converting raw HTML to clean markdown for LLMs |
| [**research**](https://github.com/hanzoai/research) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1334](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1334-research-unified-runtime.md) | Autonomous scientific research harness structuring tasks as falsifiable runs |
| [**vector**](https://github.com/hanzoai/vector) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0401](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0401-datastore-crd.md) | HNSW vector database for high-dimensional embeddings and semantic search |
| [**graph**](https://github.com/hanzoai/graph) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1198](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1198-graph-assertion-plane.md) | Distributed GraphQL & graph database engine over [`luxfi/zapdb`](https://github.com/luxfi/zapdb) posting lists |

### 9. Frontend Substrate, Components & Workspace Apps
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**gui**](https://github.com/hanzoai/gui) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0504](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0504-unified-design-system.md) | Universal styling library & optimizing compiler (`@hanzo/gui`, `@hanzogui/core`) |
| [**ui**](https://github.com/hanzoai/ui) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0504](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0504-unified-design-system.md) | 157+ React UI component library on `@hanzo/tokens` for Web, Expo, and Tauri |
| [**app**](https://github.com/hanzoai/app) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0528](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0528-mods-the-app-sdk.md) | Modular workspace app SDK (`@hanzo/app`) and native mod themes (`@hanzo/mod`) |
| [**build**](https://github.com/hanzoai/build) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1231](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1231-projects-the-site-store.md) | Standalone `<Builder host={...} />` app builder (`hanzo.build`) |
| [**chat**](https://github.com/hanzoai/chat) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0523](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0523-channels-one-store-two-views-many-bridges.md) | Standalone multi-brand chat client (`hanzo.chat`) |
| [**desktop**](https://github.com/hanzoai/desktop) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0115](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0115-hanzo-frontend-delivery.md) | Native cross-platform desktop application |
| [**mobile**](https://github.com/hanzoai/mobile) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0115](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0115-hanzo-frontend-delivery.md) | Native iOS & Android application built on Expo SDK 57 |
| [**extension**](https://github.com/hanzoai/extension) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0105](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0105-in-process-extension-runtime-standard.md) | Browser extension (Chrome, Firefox, Safari) and IDE plugins |

### 10. Sovereign Cloud Applications, Finance & Operations
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**admin**](https://github.com/hanzoai/admin) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1320](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1320-admin-the-operator-console.md) | SuperAdmin console (`admin.hanzo.ai`) & live `/code` agent session monitor |
| [**commerce**](https://github.com/hanzoai/commerce) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1220](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1220-commerce-the-merchant-half.md) | Multi-tenant commerce, billing & autonomous agent treasury clearinghouse |
| [**billing**](https://github.com/hanzoai/billing) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1220](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1220-commerce-the-merchant-half.md) | Customer billing console, balance, usage breakdown & crypto top-ups (`billing.hanzo.ai`) |
| [**ledger**](https://github.com/hanzoai/ledger) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1001](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1001-ledger-double-entry-ledger.md) | Programmable double-entry financial ledger (Numscript DSL, atomic multi-posting) |
| [**treasury**](https://github.com/hanzoai/treasury) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1221](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1221-treasury-the-reserve-fund.md) | Double-entry reserve fund, wallets, payment routing, and multi-tenant reconciliation |
| [**wallet**](https://github.com/hanzoai/wallet) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1161](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1161-wallet-key-custody.md) | Multi-chain SIWx signature verification, key custody & agent clearinghouse |
| [**pay**](https://github.com/hanzoai/pay) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1220](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1220-commerce-the-merchant-half.md) | Tenant-neutral embeddable checkout and payment UI (`@hanzoai/pay`) |
| [**compliance**](https://github.com/hanzoai/compliance) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1115](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1115-compliance.md) | FATF/OFAC/KYC compliance engine with zero-knowledge travel-rule, GDPR & MiCA |
| [**captable**](https://github.com/hanzoai/captable) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1111](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1111-captable.md) | Sovereign equity, cap table, and vesting management platform |
| [**esign**](https://github.com/hanzoai/esign) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1125](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1125-esign-signatures.md) | Self-hosted document e-signature platform with cryptographic tamper evidence |
| [**dataroom**](https://github.com/hanzoai/dataroom) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1121](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1121-dataroom-shared-documents.md) | Secure document sharing with watermarking, access revocation & audit logs |
| [**cms**](https://github.com/hanzoai/cms) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1116](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1116-content.md) | Headless content management substrate for documentation and marketing |
| [**trust**](https://github.com/hanzoai/trust) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0054](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0054-zero-trust-architecture-standard.md) | SOC2/ISO control inventory, posture verification & trust center (`/v1/trust/*`) |
| [**sentinel**](https://github.com/hanzoai/sentinel) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1032](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1032-errors-the-fault-lens.md) | Native exception capture, crash tracking & stack unwinder (`ghcr.io/hanzoai/sentry`) |
| [**event**](https://github.com/hanzoai/event) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1190](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1190-event-product-analytics.md) | Telemetry & event substrate (`/v1/event`, `tag.js` auto-capture) powering analytics & insights |
| [**analytics**](https://github.com/hanzoai/analytics) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1190](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1190-event-product-analytics.md) | Privacy-focused analytics platform (`analytics.hanzo.ai`) |
| [**insights**](https://github.com/hanzoai/insights) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0401](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0401-datastore-crd.md) | Data exploration & product intelligence (`insights.hanzo.ai`) |
| [**studio**](https://github.com/hanzoai/studio) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0506](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0506-hanzo-studio-agentic-creative-runtime.md) | Agent creative studio & prompt workbench (`studio.hanzo.ai`) |
| [**social**](https://github.com/hanzoai/social) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1153](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1153-social-transport-publishing.md) | Multi-channel social publishing engine (`social.hanzo.ai`) |
| [**marketing**](https://github.com/hanzoai/marketing) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1110](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1110-campaign.md) | Multi-channel lifecycle email campaigns and audience segmentation |
| [**notify**](https://github.com/hanzoai/notify) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0143](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0143-egress-outbound-trust-boundary.md) | Transactional email, SMS, and webhook routing over tenant KMS credentials |
| [**team**](https://github.com/hanzoai/team) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1048](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1048-team.md) | Sovereign team collaboration platform (`hanzo.team`) |
| [**bot**](https://github.com/hanzoai/bot) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1107](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1107-bot-runs-on-a-surface.md) | Multi-channel personal assistant gateway (`hanzo.bot`) |
| [**helpdesk**](https://github.com/hanzoai/helpdesk) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0115](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0115-hanzo-frontend-delivery.md) | Sovereign customer support and help center (`help.hanzo.ai`) |
| [**usage**](https://github.com/hanzoai/usage) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1313](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1313-usage-the-metered-record.md) | Token, API and model usage telemetry & allowance tracker (`/v1/usage`) |
| [**security**](https://github.com/hanzoai/security) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0054](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0054-zero-trust-architecture-standard.md) | Security engineering standards, threat models & vulnerability disclosure |
| [**world**](https://github.com/hanzoai/world) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0506](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0506-hanzo-studio-agentic-creative-runtime.md) | 3D spatial simulation and autonomous agent world engine (`world.hanzo.ai`) |

### 11. Sovereign DevOps, Registries & Delivery Fleet
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**git**](https://github.com/hanzoai/git) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1328](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1328-forge-the-meta-code-host.md) | Hanzo Forge git server and GitHub overlay (`forge.hanzo.ai`) |
| [**ci**](https://github.com/hanzoai/ci) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0036](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0036-ci-cd-build-system-standard.md) | Continuous Integration pipeline and reusable workflows |
| [**git-runner**](https://github.com/hanzoai/git-runner) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1230](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1230-platform-the-container-plane.md) | Ephemeral Kata Container CI job runner (`ci.hanzo.ai`) |
| [**deploy**](https://github.com/hanzoai/deploy) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1122](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1122-deploy-gitops-plane.md) | Hanzo CD sovereign continuous delivery reconciler (`cd.hanzo.ai`) |
| [**operator**](https://github.com/hanzoai/operator) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0400](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0400-service-crd.md) | Rust Kubernetes operator reconciling `App` and platform CRDs (`operator-system`) |
| [**registry**](https://github.com/hanzoai/registry) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1165](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1165-s3-buckets-and-objects.md) | Sovereign OCI container image and Helm chart registry (`oci.hanzo.ai`) backed by S-Chain |
| [**pkg**](https://github.com/hanzoai/pkg) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1144](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1144-registry-artifact-control-plane.md) | Universal package registry & mirror (`pkg.hanzo.ai`: npm, PyPI, Go, Cargo, Maven) |
| [**zt**](https://github.com/hanzoai/zt) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1173](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1173-network-the-zero-trust-overlay.md) | Zero Trust overlay networking mesh, controller PKI, and dark edge routers |
| [**dns**](https://github.com/hanzoai/dns) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1321](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1321-dns-zones-and-records.md) | Programmable DNS edge router with dynamic records and CoreDNS integration |
| [**sites**](https://github.com/hanzoai/sites) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1231](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1231-projects-the-site-store.md) | Edge static web hosting and preview deployments (`/v1/sites`) |
| [**flags**](https://github.com/hanzoai/flags) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0063](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0063-feature-flags-standard.md) | Feature flags and A/B experimentation engine (`/v1/flags`) |
| [**o11y**](https://github.com/hanzoai/o11y) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1240](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1240-o11y-the-observability-plane.md) | OpenTelemetry collector & APM ingestion pipeline backed by Datastore |
| [**plugin**](https://github.com/hanzoai/plugin) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0106](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0106-hanzo-plugin-contract.md) | Unified plugin runtime host: Go, JS, Wasm, CPython |

### 12. Blockchain Substrate & Proof of AI (PoAI)
| Repository | Documentation | Specification | Description |
| :--- | :--- | :--- | :--- |
| [**node**](https://github.com/hanzoai/node) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1020](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1020-chain-registry.md) | Sovereign `hanzod` network node in Rust (Chain ID 36963) |
| [**explorer**](https://github.com/hanzoai/explorer) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1021](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1021-chain-rpc-door.md) | Blockchain explorer for viewing and analyzing EVM-compatible chains |
| [**luxfi/consensus**](https://github.com/luxfi/consensus) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0125](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0125-consensus-plugin-placement-platform.md) | Quasar consensus engine (Photon/Wave/Focus + PQ triple-mode) |
| [**luxfi/node**](https://github.com/luxfi/node) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-1021](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1021-chain-rpc-door.md) | Go Lux node host |
| [**luxfi/mpc**](https://github.com/luxfi/mpc) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0413](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0413-mpc-crd.md) | Multi-party computation ceremony engine (FROST, CGGMP21, Pulsar) |
| [**lux-gpu/gpu**](https://github.com/lux-gpu/gpu) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0121](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0121-byo-compute-fleet-and-metered-billing.md) | GPU C ABI v10 runtime & hardware plugin loader |
| [**lux-gpu/gpu-kernels**](https://github.com/lux-gpu/gpu-kernels) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0096](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0096-ai-compute-contribution-rewards.md) | Canonical CUDA, Metal, and WGSL compute shaders |
| [**luxfhe/torus**](https://github.com/luxfhe/torus) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0125](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0125-consensus-plugin-placement-platform.md) | Torus FHE compiler (Python/MLIR ➔ GPU vtbl) |
| [**PoAI**](https://github.com/luxfi/standard) | [docs.hanzo.ai](https://docs.hanzo.ai) | [HIP-0901](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0901-proof-of-ai-native-execution-proofs.md) | Proof of AI verification contracts (PoI, PoT, PoE, PoC) |

### 13. Production Cloud App Services & Subsystems (HIP-0106)

Governed by [**HIP-0106: The Hanzo Plugin Contract**](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0106-hanzo-plugin-contract.md), [`hanzoai/cloud`](https://github.com/hanzoai/cloud) operates as a unified, light host that dynamically discovers and lazy-loads over **140+ modular production app plugins** (`apps/*`) under `/v1/*` without code divergence:

* **Sovereign Identity, Account & Governance**: [`account`](https://github.com/hanzoai/account) ([HIP-1200](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1200-account.md)), `admission` ([HIP-1201](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1201-admission.md)), [`compliance`](https://github.com/hanzoai/compliance) ([HIP-1115](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1115-compliance.md)), `principal` ([HIP-1340](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1340-principal-identity-statements-and-clearance.md)), [`trust`](https://github.com/hanzoai/trust) ([HIP-0054](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0054-zero-trust-architecture-standard.md)), [`security`](https://github.com/hanzoai/security) ([HIP-0054](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0054-zero-trust-architecture-standard.md)), [`iam`](https://github.com/hanzoai/iam) ([HIP-0111](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0111-iam-authentication-standard.md)), [`kms`](https://github.com/hanzoai/kms) ([HIP-0136](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0136-one-secret-one-path.md)), [`mpc`](https://github.com/hanzoai/mpc) ([HIP-0413](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0413-mpc-crd.md)).
* **Commerce, Finance & Corporate Rails**: [`billing`](https://github.com/hanzoai/billing) ([HIP-1220](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1220-commerce-the-merchant-half.md)), [`commerce`](https://github.com/hanzoai/commerce) ([HIP-1220](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1220-commerce-the-merchant-half.md)), `marketplace` ([HIP-1335](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1335-listings-one-market-for-apps-skills-mods-plugins.md)), [`ledger`](https://github.com/hanzoai/ledger) ([HIP-1001](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1001-ledger-double-entry-ledger.md)), [`treasury`](https://github.com/hanzoai/treasury) ([HIP-1221](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1221-treasury-the-reserve-fund.md)), [`wallet`](https://github.com/hanzoai/wallet) ([HIP-1161](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1161-wallet-key-custody.md)), [`captable`](https://github.com/hanzoai/captable) ([HIP-1111](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1111-captable.md)), `tax` ([HIP-1338](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1338-tax-informational-returns-and-w9-compliance.md)), `patent` ([HIP-1336](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1336-patent-inventorship-conception-provenance.md)), [`usage`](https://github.com/hanzoai/usage) ([HIP-1313](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1313-usage-the-metered-record.md)), `pricing` ([HIP-1106](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1106-blueprint-priced-stack.md)), `allowance` ([HIP-1101](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1101-allowance-free-ceiling.md)).
* **Documents, Contracts & Knowledge**: [`esign`](https://github.com/hanzoai/esign) ([HIP-1125](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1125-esign-signatures.md)), [`dataroom`](https://github.com/hanzoai/dataroom) ([HIP-1121](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1121-dataroom-shared-documents.md)), [`cms`](https://github.com/hanzoai/cms) ([HIP-1116](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1116-content.md)), [`helpdesk`](https://github.com/hanzoai/helpdesk) ([HIP-0115](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0115-hanzo-frontend-delivery.md)), `knowledge` ([HIP-1147](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1147-search-hybrid-retrieval.md)), `content` ([HIP-1116](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1116-content.md)).
* **AI, Models & Scientific Research**: [`ai`](https://github.com/hanzoai/ai) ([HIP-1211](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1211-ai-the-model-api.md)), [`agents`](https://github.com/hanzoai/agents) ([HIP-1210](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1210-agents-define-run-keep.md)), [`zen`](https://github.com/hanzoai/zen) ([HIP-0096](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0096-ai-compute-contribution-rewards.md)), [`engine`](https://github.com/hanzoai/engine) ([HIP-1124](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1124-engine-runtime-lens.md)), [`research`](https://github.com/hanzoai/research) ([HIP-1334](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1334-research-unified-runtime.md)), [`world`](https://github.com/hanzoai/world) ([HIP-0506](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0506-hanzo-studio-agentic-creative-runtime.md)), [`eval`](https://github.com/hanzoai/eval) ([HIP-1105](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1105-benchmark-measurement-arena.md)), `benchmark` ([HIP-1105](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1105-benchmark-measurement-arena.md)), `prompt` ([HIP-1211](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1211-ai-the-model-api.md)).
* **Search, Crawl & Code Intelligence**: [`search`](https://github.com/hanzoai/search) ([HIP-1147](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1147-search-hybrid-retrieval.md)), [`index`](https://github.com/hanzoai/index) ([HIP-1132](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1132-index-search.md)), [`crawl`](https://github.com/hanzoai/crawl) ([HIP-1117](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1117-crawl.md)), [`code`](https://github.com/hanzoai/code) ([HIP-1114](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1114-code.md)), [`lsp`](https://github.com/hanzoai/lsp) ([HIP-1214](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1214-lsp-live-code-intelligence.md)), [`graph`](https://github.com/hanzoai/graph) ([HIP-1198](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1198-graph-assertion-plane.md)).
* **Cloud Infrastructure, Telemetry & Networking**: [`compute`](https://github.com/hanzoai/compute) ([HIP-1172](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1172-visor-compute-you-rent.md)), `environment` ([HIP-1339](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1339-environment-codebase-preflight-and-secrets.md)), `space` ([HIP-1337](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1337-space-workspaces-drives-and-files.md)), [`dns`](https://github.com/hanzoai/dns) ([HIP-1321](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1321-dns-zones-and-records.md)), [`flags`](https://github.com/hanzoai/flags) ([HIP-0063](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0063-feature-flags-standard.md)), [`functions`](https://github.com/hanzoai/functions) ([HIP-0060](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0060-serverless-functions-standard.md)), [`o11y`](https://github.com/hanzoai/o11y) ([HIP-1240](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1240-o11y-the-observability-plane.md)), [`pubsub`](https://github.com/hanzoai/pubsub) ([HIP-1060](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1060-pubsub-the-tenant-door-on-the-bus.md)), [`kafka`](https://github.com/hanzoai/kafka) ([HIP-1323](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1323-kafka-the-wire-every-client-speaks.md)), [`amqp`](https://github.com/hanzoai/amqp) ([HIP-1326](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1326-amqp-exchanges-queues-and-bindings.md)), [`mq`](https://github.com/hanzoai/mq) ([HIP-1326](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1326-amqp-exchanges-queues-and-bindings.md)), [`sites`](https://github.com/hanzoai/sites) ([HIP-1231](https://github.com/hanzoai/hips/blob/main/HIPs/hip-1231-projects-the-site-store.md)), [`plugin`](https://github.com/hanzoai/plugin) ([HIP-0106](https://github.com/hanzoai/hips/blob/main/HIPs/hip-0106-hanzo-plugin-contract.md)).

</details>

---

## Public Open-Source vs. Sovereign Enterprise Cloud

Hanzo operates on a clean separation between **Open Source Foundation (`hanzoai/*`)** and **Enterprise Sovereign Cloud**:

```
                       The Sovereign Developer Stack
                                     │
      ┌──────────────────────────────┴──────────────────────────────┐
      ▼                                                             ▼
1. PUBLIC OPEN-SOURCE (hanzoai/*)             2. HANZO SOVEREIGN CLOUD 
Fork & Assemble Architecture                   Private Cloud Control Plane
• 100% Sovereign & Self-Hostable               • Proprietary C/C++ AOT via hanzoai/wasm2go
• Single-binary local dev (hanzoai/cloud)     • Bare-metal & GPU manager (apps/visor)
• BaaS data plane (hanzoai/base + SQLite)      • In-cluster BuildKit engine (apps/platform)
• Multi-tenant REST & ZAP streaming            • EIP-712 USDC crypto clearinghouse
• Open MCP tools (AST, LSP, tgrep, vector)     • Kai decision engine & calibration models
• Standard Docker & Helm deployments           • Hardware HSM & Quorum MPC consensus
```

* **Fork and Assemble Locally**: Developers can freely fork public repos, assemble their own backend or AI agent mesh on top of Hanzo's canonical `/v1/*` REST and ZAP binary endpoints, and deploy to their own infrastructure with zero external telemetry or cloud lock-in.
* **Enterprise Cloud Enclave**: The managed cloud fleet (`cloud.hanzo.ai`, `platform.hanzo.ai`) uses [`wasm2go`](https://github.com/hanzoai/wasm2go) to compile high-performance native kernels directly into Go assembly (`amd64.s`/`arm64.s`), eliminating CGo toolchains while providing high-throughput machine scheduling, JIT runner allocation, and hardware-attested enclave execution.

---

## Clone the Sovereign Fleet: Get All Hanzo Repositories

Clone all 700+ repositories across the Hanzo open-source fleet with a single parallel command:

```bash
# Clone the complete Hanzo OSS fleet (700+ repos) into ./hanzo-repos with 16 parallel workers
curl -fsSL https://raw.githubusercontent.com/hanzoai/.github/main/scripts/clone-all.sh | bash -s -- -j 16
```

Or using the GitHub CLI directly with `xargs`:
```bash
# Stream repo list and clone concurrently
gh repo list hanzoai --limit 1000 --json name --template '{{range .}}{{if not .isArchived}}{{.name}}{{"\n"}}{{end}}{{end}}' | \
  xargs -P 16 -I {} git clone https://github.com/hanzoai/{}.git hanzo-repos/hanzoai/{}
```

For enterprise members with access to Hanzo Enterprise:
```bash
# Clone both public OSS and private enterprise enclaves concurrently via SSH:
curl -fsSL https://raw.githubusercontent.com/hanzoai/.github/main/scripts/clone-all.sh | bash -s -- -o "hanzoai,hanzo-enterprise" -j 16
```

---

<p align="center">
  <strong>Hanzo AI, Inc. — Techstars '17</strong><br>
  Open Source under Apache-2.0 and MIT per <a href="https://github.com/hanzoai/hips/blob/main/HIPs/hip-0137-one-license.md">HIP-0137</a>.
</p>
