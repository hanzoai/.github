# Permanent Autonomous PR Convergence

Every pull request across `hanzoai/*` and `hanzo-inc/*` MUST converge cleanly to a terminal disposition. Long-lived stalled draft PRs, duplicate implementations, and circular blockers are prohibited.

## Required PR Metadata

Every non-trivial PR MUST specify:
1. **Canonical owning repository** (no forks, duplicate services, or legacy repositories).
2. **Qualification criteria** (functional invariants, tests, race/fuzz checks, or benchmarks required before merge).
3. **Verification evidence** (exact CI run IDs, test counts, benchmark numbers, and live receipts where applicable).
4. **Security review** (auth/IAM/KMS/tenant-isolation/input-validation posture; Cyber qualification for auth, billing, token, or boundary changes).
5. **Rollout and rollback plan** (deployment pin, migration continuity, and revert path).

## Allowed Dispositions

Every open PR resolves to exactly one of five dispositions:

| Disposition | Meaning |
|---|---|
| `MERGE` | Qualified against current `main`, CI/security/benchmark gates green, merged and released/deployed as applicable. |
| `FIX` | Deficiencies identified and repaired on the branch (rebased onto `main`, conflicts resolved, failing gates fixed) prior to `MERGE`. |
| `SUPERSEDE` | Replaced by a clean PR on current `main` (or the canonical owning repository) preserving all required guarantees; original PR closed with a pointer to the replacement. |
| `CLOSE` | Obsolete, duplicate, or invalidated by newer qualified functionality on `main`; closed with clear engineering rationale. |
| `GATED` | Implementation qualified on non-production / testnet targets, with production or regulated public launch explicitly gated on external legal, compliance, or operator approval (never bypassed autonomously). |

## Engineering Invariants

- **Canonical ownership**: One implementation per concern in the canonical repository; delete obsolete duplicates after migration is verified.
- **No shortcuts**: Never commit local `replace` or `[patch.crates-io]` overrides, temporary forks, disabled CI gates, or unverified claims.
- **Automated qualification**: Sci, QA, and Cyber automated verification qualifies engineering changes; merge only on green CI.
- **Deployment vs. build**: Never confuse a green build with a verified production deployment.
- **Regulatory boundary**: Never launch regulated financial products or public token sales without legal qualification and explicit launch authorization.

## External Research & Bounty PR Policy

Every external research and bounty PR across `hanzoai/*` and `hanzo-inc/*` MUST satisfy four invariants:

1. **Public reproducibility**: Evaluate on real, appropriately licensed, versioned public datasets with deterministic seeds and documented commands. Reserve synthetic data strictly for deterministic unit tests.
2. **Private qualification**: Hanzo private evaluation corpora, proprietary routing data, and confidential labels are **never** exported externally. Contributors implement the reproducible benchmark harness; authorized Hanzo runners execute confidential qualification internally and publish approved aggregate-only receipts.
3. **Canonical implementation**: Consume canonical Hanzo registries, catalogs, and shipping implementations as baselines. Do not introduce duplicate routers, pricing tables, or permanently disconnected research prototypes.
4. **Measurable improvement**: Production integration and bounty acceptance require verified improvement in quality, cost, latency, or reliability over the shipping baseline. No payment or merge for unsubstantiated or synthetic-only performance claims.
