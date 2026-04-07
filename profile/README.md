# Hanzo AI

AI infrastructure for the agentic era. LLM gateway, MCP tools, multi-agent SDKs, and developer tools for building, deploying, and managing AI applications at scale.

[![Discord](https://img.shields.io/discord/1234567890?label=Discord&logo=discord)](https://discord.gg/hanzo)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Hanzo AI (Techstars '17) provides the complete AI development stack -- from model serving through 100+ LLM providers, to 260+ MCP tools for AI agents, to multi-agent orchestration SDKs, and full-stack deployment infrastructure. Built for developers shipping AI-native applications.

## Quick Start

```bash
# LLM Gateway -- unified proxy for 100+ providers
pip install hanzo
hanzo gateway --port 4000

# MCP Tools -- 260+ tools for AI agents
npm install -g @hanzo/mcp

# AI coding agent in your terminal
pip install hanzo-dev
hanzo-dev
```

## Architecture

```
Applications:  Chat  |  Search  |  Code  |  Dev  |  Flow
                     |          |        |       |
Gateway:       LLM Gateway (100+ providers, load balancing, caching)
                     |
Protocol:      Model Context Protocol (260+ tools)
                     |
Models:        Jin (multimodal)  |  Zen LM (frontier)  |  Any provider
                     |
Compute:       Hanzo Network (decentralized AI compute)
```

## Core Projects

### Infrastructure
| Project | Description |
|---------|-------------|
| [gateway](https://github.com/hanzoai/gateway) | Unified LLM gateway -- 100+ providers, load balancing, caching |
| [mcp](https://github.com/hanzoai/mcp) | Model Context Protocol server with 260+ tools for AI agents |
| [agent](https://github.com/hanzoai/agent) | Multi-agent SDK with OpenAI-compatible API |
| [console](https://github.com/hanzoai/console) | LLM dev environment -- debug, fine-tune, monitor |
| [cloud](https://github.com/hanzoai/cloud) | Unified AI infrastructure and MCP management platform |

### Developer Tools
| Project | Description |
|---------|-------------|
| [code](https://github.com/hanzoai/code) | Open source AI code editor -- any model, full data control |
| [dev](https://github.com/hanzoai/dev) | AI coding agent in your terminal |
| [cli](https://github.com/hanzoai/cli) | Deploy, manage, and interact with AI infrastructure |
| [flow](https://github.com/hanzoai/flow) | Visual drag-and-drop AI workflow builder |
| [search](https://github.com/hanzoai/search) | AI-powered search with generative UI |

### SDKs
| Language | Package |
|----------|---------|
| Python | [python-sdk](https://github.com/hanzoai/python-sdk) -- `pip install hanzo` |
| TypeScript | [js-sdk](https://github.com/hanzoai/js-sdk) -- `npm install @hanzo/api` |
| Go | [go-sdk](https://github.com/hanzoai/go-sdk) -- `go get github.com/hanzoai/go-sdk` |
| Rust | [rust-sdk](https://github.com/hanzoai/rust-sdk) -- `cargo add hanzo` |

### AI Research
| Project | Description |
|---------|-------------|
| [jin](https://github.com/hanzoai/jin) | Multimodal AI -- vision, audio, 3D embeddings |
| [operative](https://github.com/hanzoai/operative) | Autonomous computer use agent for Claude |
| [node](https://github.com/hanzoai/node) | Hanzo Network node for decentralized AI compute |
| [contracts](https://github.com/hanzoai/contracts) | Smart contracts -- ERC20, staking, governance |

## Key Protocols

| Protocol | Proposal | Purpose |
|----------|----------|---------|
| ASO | HIP-002 | Active Semantic Optimization |
| HMM | HIP-004 | Hamiltonian Market Maker |

## Ecosystem

| Organization | Focus | Link |
|---|---|---|
| **Hanzo AI** | AI infrastructure, LLM gateway, MCP tools | [github.com/hanzoai](https://github.com/hanzoai) |
| **Lux Network** | Post-quantum blockchain, FHE, multi-consensus | [github.com/luxfi](https://github.com/luxfi) |
| **Zen LM** | Frontier language models, 600M-480B parameters | [github.com/zenlm](https://github.com/zenlm) |
| **Zoo Labs** | Open AI research, DeSci, 501(c)(3) foundation | [github.com/zoo-labs](https://github.com/zoo-labs) |
| **Lux FHE** | Fully homomorphic encryption research + SDK | [github.com/luxfhe](https://github.com/luxfhe) |
| **Lux C++** | High-performance C++ libraries | [github.com/luxcpp](https://github.com/luxcpp) |
| **Hanzo KMS** | Enterprise secret management | [github.com/hanzokms](https://github.com/hanzokms) |
| **Hanzo ID** | Identity, OAuth2/OIDC, WebAuthn | [github.com/hanzoid](https://github.com/hanzoid) |

### Links
- [Papers](https://github.com/luxfi/papers) -- 329+ research papers
- [Stats](https://zeekay.github.io/stats/) -- 38,906+ commits, 59M net LOC
- [Security](https://github.com/luxfi/node/blob/main/SECURITY.md) -- cryptographic audit trail
- [History](https://github.com/luxfi/node/blob/main/HISTORY.md) -- 2008-2026 timeline

## Resources

- [hanzo.ai](https://hanzo.ai) -- Website
- [docs.hanzo.ai](https://docs.hanzo.ai) -- Documentation
- [hanzo.network](https://hanzo.network) -- Compute marketplace

Apache 2.0 -- See individual repositories for details.

*Hanzo AI Inc. -- Techstars '17 -- San Francisco*
