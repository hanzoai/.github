# Hanzo

Open-source AI infrastructure. The parts below run on your own machine with no
account; the hosted cloud at `api.hanzo.ai` adds sign-in, billing and hosted models.

[hanzo.ai](https://hanzo.ai) · [docs.hanzo.ai](https://docs.hanzo.ai) · [hanzoskills.com](https://hanzoskills.com)

## Run it on your own machine

| Repository | What it is | Start it |
|---|---|---|
| [base](https://github.com/hanzoai/base) | SQLite application backend, one Go binary | in a clone: `go run ./examples/base serve`, then `http://127.0.0.1:8090/v1/` |
| [cloud](https://github.com/hanzoai/cloud) | the open-source cloud, one Go binary with the console built in | in a clone: `make build && CLOUD_DEV_UNENCRYPTED=1 CLOUD_LISTEN=127.0.0.1:8080 CLOUD_DATA_DIR=.dev/data ./cloud`, then `http://127.0.0.1:8080` |
| [zip](https://github.com/zap-proto/zip) | Go framework: an operation declared once is served as REST, OpenAPI and an MCP tool | in a clone: `go run ./examples/hello`, then `http://localhost:8080/hello` |
| [mcp](https://github.com/hanzoai/mcp) | MCP server for coding agents | `npx -y --package=@hanzo/mcp hanzo-mcp serve` (stdio) |
| [engine](https://github.com/hanzoai/engine) | model inference, in Rust | `cargo install --git https://github.com/hanzoai/engine --locked hanzo-cli`, then `hanzo-engine serve -m <model-id>`, on `http://localhost:1234/v1` |

The cloud command runs unencrypted, for local development only: its `make dev`
cannot encrypt a store yet.

## Use the hosted cloud

```bash
curl -fsSL https://hanzo.sh | sh    # hanzo, hanzo-mcp and dev, into ~/.local/bin
hanzo auth login                    # sign in with Hanzo IAM
```

The API is `https://api.hanzo.ai/v1/`, and every operation is documented at
[docs.hanzo.ai](https://docs.hanzo.ai).

## For coding agents

```bash
curl hanzoskills.com/skill.md    # what runs locally, what needs an account, how to work either way
curl hanzoskills.com/llms.txt    # every skill and specification
```

## Where things live

| Repository | What it is |
|---|---|
| [cli](https://github.com/hanzoai/cli) | `hanzo`: a coding agent, and every hosted product from the terminal |
| [iam](https://github.com/hanzoai/iam) | identity: the sign-in every Hanzo service uses |
| [kms](https://github.com/hanzoai/kms) | secrets |
| [gateway](https://github.com/hanzoai/gateway) | the edge of `api.hanzo.ai`: identity, rate limits, metering |
| [ui](https://github.com/hanzoai/ui) · [gui](https://github.com/hanzoai/gui) · [design](https://github.com/hanzoai/design) | React components, the cross-platform UI framework, design tokens |
| [python-sdk](https://github.com/hanzoai/python-sdk) · [js-sdk](https://github.com/hanzoai/js-sdk) · [sdk](https://github.com/hanzoai/sdk) | SDKs |
| [dev](https://github.com/hanzoai/dev) | a coding agent for the terminal |
| [hips](https://github.com/hanzoai/hips) | design specifications |

[All repositories](https://github.com/orgs/hanzoai/repositories)

Hanzo AI, Inc. — Techstars '17
