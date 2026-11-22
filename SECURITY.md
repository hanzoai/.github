# Security Policy

Hanzo AI takes the security of our open-source software, native binaries, and cloud infrastructure seriously.

## Reporting a Vulnerability

**Do not report security vulnerabilities in a public issue, pull request, or discussion.**

Report vulnerabilities privately through either channel:

1. **GitHub Private Vulnerability Reporting**: Open the affected repository's **Security** tab and choose **Report a vulnerability**.
2. **Direct email**: Send details to **[security@hanzo.ai](mailto:security@hanzo.ai)** (also published via RFC 9116 at [`https://hanzo.ai/.well-known/security.txt`](https://hanzo.ai/.well-known/security.txt)).

Please include:
- The affected repository, release version, or service endpoint
- Clear reproduction steps or a minimal proof of concept
- Expected impact and any suggested remediation

We acknowledge receipt promptly, coordinate remediation with you, and ask that you allow us to ship a fix before public disclosure.

## Verifying Releases & Binaries

Every official Hanzo binary is built from public source in GitHub Actions and published to GitHub Releases with SHA-256 checksums:

- **Checksum verification**: `curl -fsSL https://hanzo.sh | sh` downloads prebuilt native binaries directly from GitHub Releases and verifies SHA-256 checksums before installation.
- **Strict provenance mode**: Pass `--strict` to require GitHub release attestation verification before installing:
  ```sh
  curl -fsSL https://hanzo.sh | sh -s -- --strict
  ```
- **Inspect before running**: View the POSIX installer source at [`hanzoai/hanzo.sh`](https://github.com/hanzoai/hanzo.sh) and [`hanzoai/cli/install.sh`](https://github.com/hanzoai/cli/blob/main/install.sh), or run `hanzo doctor --verify` on an existing install.
- **Build from source**: All core tools (`hanzoai/cli`, `hanzoai/engine`, `hanzoai/cloud`, `hanzoai/desktop`) can be compiled directly from source without using prebuilt binaries.
- **Code signing**: Official Hanzo Desktop installers are signed via hardware-backed KMS keys (Windows EV RSA-4096 SHA-256 via GitHub Actions OIDC Workload Identity Federation; macOS signed and notarized builds).

## Architecture & Controls

For encryption standards, zero-trust KMS/MPC key management, network isolation, and compliance details, see **[hanzo.ai/security](https://hanzo.ai/security)**.
