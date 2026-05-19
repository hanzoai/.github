# Hanzo AI — Open Source

The Hanzo OSS estate, mapped.

## Start here

```bash
curl -fsSL hanzo.sh | bash
hanzo init my-app
hanzo dev
```

## Canonical taxonomy

### Core platform
| Repo | Role |
|---|---|
| [cloud](https://github.com/hanzoai/cloud) | Unified Go control plane and binary (HIP-0106) |
| [zip](https://github.com/hanzoai/zip) | Canonical Go web framework, Fiber v3-based |
| [base](https://github.com/hanzoai/base) | Per-tenant SQLite + extension runtimes (HIP-0105) |
| [iam](https://github.com/hanzoai/iam) | Identity, OAuth2/OIDC/SAML |
| [kms](https://github.com/hanzoai/kms) | Secrets and signing |
| [gateway](https://github.com/hanzoai/gateway) | HTTP gateway: routing, JWT, identity strip |
| [vfs](https://github.com/hanzoai/vfs) | Object-store abstraction (HIP-0107) |
| [commerce](https://github.com/hanzoai/commerce) | Checkout + billing (light router; NOT in PCI scope) |
| [o11y](https://github.com/hanzoai/o11y) | Metrics + traces + logs |

### Agent + tooling
| Repo | Role |
|---|---|
| [mcp](https://github.com/hanzoai/mcp) | Model Context Protocol (HIP-0300 unified tools) |
| [agents](https://github.com/hanzoai/agents) | Multi-agent orchestration |
| [brain](https://github.com/hanzoai/brain) | Memory + RAG |
| [ai](https://github.com/hanzoai/ai) | LLM control plane + RAG + model hub |

### SDKs
| Repo | Lang |
|---|---|
| [zip-rs](https://github.com/hanzoai/zip-rs) | Rust handler SDK (wasm output) |
| [zip-js](https://github.com/hanzoai/zip-js) | TypeScript handler SDK |
| [python-sdk](https://github.com/hanzoai/python-sdk) | Python SDK |
| [go-sdk](https://github.com/hanzoai/go-sdk) | Go SDK |
| [rust-sdk](https://github.com/hanzoai/rust-sdk) | Rust SDK with crypto/DID |
| [js-sdk](https://github.com/hanzoai/js-sdk) | TypeScript client library |

### Apps
| Repo | Role |
|---|---|
| [chat](https://github.com/hanzoai/chat) | Hanzo Chat — 14 Zen models + MCP tools |
| [platform](https://github.com/hanzoai/platform) | PaaS deployment UI |
| [console](https://github.com/hanzoai/console) | LLM dev + evals + prompt management |
| [desktop](https://github.com/hanzoai/desktop) | Desktop agent client |
| [flow](https://github.com/hanzoai/flow) | Visual workflow builder |
| [bot](https://github.com/hanzoai/bot) | Channel adapter framework |

### Isolated workers
| Repo | Lang | Why isolated |
|---|---|---|
| [vault](https://github.com/hanzoai/vault) | Go | PCI-DSS CDE (the only system that touches PAN) |
| [payments](https://github.com/hanzoai/payments) | Rust | PCI-CDE-connected, payment orchestration |
| [datastore](https://github.com/hanzoai/datastore) | C++ | OLAP column store |
| [engine](https://github.com/hanzoai/engine) | Rust | Inference worker (CUDA/Metal/CPU) |
| [insights](https://github.com/hanzoai/insights) | Python | LLM observability + evals + prompt mgmt |

### Specs
| Repo | Role |
|---|---|
| [HIPs](https://github.com/hanzoai/HIPs) | Hanzo Improvement Proposals — protocol specs |

## Architecture

- **Unified binary** (HIP-0106): single Go process mounts iam, kms, base, commerce, ai, gateway, o11y, vfs, mq, dns, amqp, mcp via the `Mount(*zip.App, cloud.Deps) error` contract.
- **Extension runtimes** (HIP-0105): user code runs in goja (JS), pyvm (Python), wazero (Rust/AS/wasm), starkvm (Starlark policy DSL).
- **Per-tenant SQLite** (HIP-0302): each org gets its own SQLite file with KMS-derived DEK; replicated to S3 via [replicate](https://github.com/hanzoai/replicate).
- **PCI isolation**: vault is the only L1-audited CDE; payments and commerce are CDE-connected; everything else is out of scope.
- **White-label**: same binary, different brand at startup. Fork [hanzoai/cloud](https://github.com/hanzoai/cloud) to launch your own ecosystem.

## Get involved

- Specs: [HIPs](https://github.com/hanzoai/HIPs)
- Security: see `SECURITY.md` in any core repo
- PR response: 48 hours
- License: BSD-3, Apache-2.0, or MIT per repo

```
HIPs implemented:
- HIP-0014 Application Deployment
- HIP-0026 IAM
- HIP-0027 KMS
- HIP-0037 AI Cloud Platform
- HIP-0060 Serverless Functions
- HIP-0105 In-Process Extension Runtime
- HIP-0106 Unified Cloud Binary
- HIP-0107 Streaming Replication over VFS
- HIP-0302 Encrypted SQLite + ZapDB Durability
```
