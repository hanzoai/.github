# Hanzo AI 🤖

**Frontier AI Infrastructure**

Hanzo AI (Techstars '17) builds cutting-edge AI infrastructure including LLMs, agent frameworks, and decentralized compute networks.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Hanzo AI Stack                             │
├─────────────────────────────────────────────────────────────────┤
│  Applications                                                   │
│  ┌──────────┬─────────────┬───────────────┬──────────────┐      │
│  │   Chat   │   Search    │    Agents     │   Platform   │      │
│  └────┬─────┴──────┬──────┴───────┬───────┴───────┬──────┘      │
│       │            │              │               │             │
│  ┌────▼────────────▼──────────────▼───────────────▼──────┐      │
│  │              LLM Gateway (100+ providers)              │      │
│  └────┬──────────────────────────────────────────────────┘      │
│       │                                                         │
│  ┌────▼────────────────────────────────────────────────────┐    │
│  │           Model Context Protocol (MCP)                  │    │
│  │                  260+ Tools                              │    │
│  └────┬────────────────────────────────────────────────────┘    │
│       │                                                         │
│  ┌────▼────────────────────────────────────────────────────┐    │
│  │          Jin (Multimodal) • Candle (Rust ML)            │    │
│  └────┬────────────────────────────────────────────────────┘    │
│       │                                                         │
│  ┌────▼────────────────────────────────────────────────────┐    │
│  │         Hanzo Network (Decentralized Compute)           │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## 📦 Core Repositories

### AI Infrastructure
| Repository | Description | Language |
|------------|-------------|----------|
| [llm](https://github.com/hanzoai/llm) | LLM Gateway (100+ providers) | Python |
| [mcp](https://github.com/hanzoai/mcp) | Model Context Protocol tools | TypeScript |
| [agent](https://github.com/hanzoai/agent) | Multi-agent SDK | Python |
| [jin](https://github.com/hanzoai/jin) | Multimodal LLM framework | Python |
| [candle](https://github.com/hanzoai/candle) | Rust ML framework | Rust |

### Applications
| Repository | Description | Language |
|------------|-------------|----------|
| [chat](https://github.com/hanzoai/chat) | AI chat interface | TypeScript |
| [search](https://github.com/hanzoai/search) | AI-powered search | TypeScript |
| [flow](https://github.com/hanzoai/flow) | Visual workflow builder | TypeScript |
| [platform](https://github.com/hanzoai/platform) | PaaS platform | TypeScript |
| [operative](https://github.com/hanzoai/operative) | Computer use agent | Python |

### SDKs
| Repository | Description | Language |
|------------|-------------|----------|
| [python-sdk](https://github.com/hanzoai/python-sdk) | Python SDK (8 packages) | Python |
| [js-sdk](https://github.com/hanzoai/js-sdk) | TypeScript SDK | TypeScript |
| [go-sdk](https://github.com/hanzoai/go-sdk) | Go SDK | Go |
| [rust-sdk](https://github.com/hanzoai/rust-sdk) | Rust SDK | Rust |

### Network & Compute
| Repository | Description | Language |
|------------|-------------|----------|
| [node](https://github.com/hanzoai/node) | Compute node | Rust |
| [mpc](https://github.com/hanzoai/mpc) | Multi-party computation | Go |
| [docs](https://github.com/hanzoai/docs) | Documentation | TypeScript |

## 🚀 Quick Start

### LLM Gateway
```bash
cd llm
make dev
# Available at http://localhost:4000
```

### MCP Tools
```bash
npm install -g @hanzo/mcp
hanzo-mcp --help
```

### Chat
```bash
cd chat
make up
# Available at http://localhost:3081
```

## 🔗 Related Organizations

| Organization | Focus | Link |
|--------------|-------|------|
| **Hanzo AI** | AI infrastructure | [github.com/hanzoai](https://github.com/hanzoai) |
| **Zen LM** | Frontier models (600M-480B) | [github.com/zenlm](https://github.com/zenlm) |
| **Lux Network** | Blockchain settlement | [github.com/luxfi](https://github.com/luxfi) |
| **Lux FHE** | Private computation | [github.com/luxfhe](https://github.com/luxfhe) |
| **Zoo Labs** | Open AI research | [github.com/zoo-labs](https://github.com/zoo-labs) |

## 📋 Key Protocols

| Protocol | HIP | Purpose |
|----------|-----|---------|
| **ASO** | HIP-002 | Active Semantic Optimization |
| **HMM** | HIP-004 | Hamiltonian Market Maker |
| **DSO** | ZIP-001 | Decentralized Semantic Optimization |
| **PoAI** | ZIP-002 | Proof of AI |

## 📚 Resources

- **Website:** [hanzo.ai](https://hanzo.ai)
- **Docs:** [docs.hanzo.ai](https://docs.hanzo.ai)
- **Network:** [hanzo.network](https://hanzo.network)

## 📄 License

Apache 2.0 - See individual repositories for details.

---

**Hanzo AI Inc. • Techstars '17 • San Francisco**
