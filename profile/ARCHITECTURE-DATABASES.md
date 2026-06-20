# Architecture Decision: Databases

Canonical. Other repos link here. Supersedes any per-repo storage choice.

Settled position:

> We can keep a scalable Postgres + DocDB on top of that to resell to
> customers, but it must be clear we aren't using this. We're focused on
> SQLite per org + user + project for all of our apps. It should be simple
> for people to just launch kv/sql from Platform / PaaS.

One canonical answer per role. Internal app → **Base** (per-tenant SQLite).
Customer-facing datastore → **PaaS catalog** product. No third option.

---

## Cross-cutting (all in-flight migrations read this first)

1. **Auth boundary is unchanged.** Tenancy is still `owner` claim from IAM
   OIDC. SQLite changes the *file*, not the *scope*. One Base file per
   `(org, user, project)`; the JWT `owner` selects the file. Do not add a
   tenant column — the file *is* the tenant boundary. KMS-derived DEK per
   file (HIP-0302), replicated to S3 via `replicate` (HIP-0107).
2. **No Postgres-only SQL survives the cut.** SQLite has no `jsonb`, no
   native arrays, no `CREATE TYPE` enums, no `timestamptz`, no advisory
   locks. Convert: enum → `TEXT` + `CHECK`; `T[]` → JSON-encoded `TEXT`;
   `jsonb`/`Json` → `TEXT`; `timestamptz` → `TEXT` ISO-8601 / `INTEGER`
   epoch; advisory locks → NATS (see #3). Re-emit migrations from the
   SQLite dialect; do not hand-edit Postgres DDL.
3. **Cross-tenant coordination is NATS, not the database.** Leader
   election, pub/sub, job queues → `nats.hanzo.svc:4222` (live in cluster
   116d). No Postgres advisory locks, no shared-table polling. Per-tenant
   SQLite has no cross-file locking and must not grow one.
4. **Lockfile + dialect churn is expected and must be committed.** Prisma
   `provider` and Drizzle `dialect` flips change generated clients and
   lockfiles. Commit the regenerated lock and migration meta in the same
   PR. Do not leave a half-migrated `_journal.json`.

---

## Decisions

1. **Internal apps → Base (per-tenant SQLite).** Every Hanzo app stores
   in Base, one SQLite file per `(org, user, project)`, KMS-DEK encrypted,
   S3-replicated. This is HIP-0105/0106/0302. There is no other internal
   store.

2. **Postgres / Redis / DocDB / MongoDB / pgvector are products, not infra.**
   They are provisioned *by customers, for customer workloads* through the
   PaaS catalog. Hanzo does **not** consume them internally. If an internal
   app reaches for Postgres, that is a bug to fix, not a pattern to follow.

3. **PaaS catalog = the storefront.** Under "Customer Databases":
   Postgres, Redis/KV, DocDB (FerretDB / Mongo-wire), MongoDB-compat,
   MariaDB/MySQL, and RAG-with-pgvector. Alongside existing DOKS / app
   services. These are billable products with their own lifecycle —
   provision, scale, snapshot, bill — not Hanzo-internal dependencies.

4. **`hanzo-sql` (shared cluster Postgres) is decommissioned.** It dies
   once platform, esign, and rag-api have migrated off (in progress). The
   *operator's* Postgres CRD **stays** — that is how customers provision
   their own Postgres through the catalog. We delete the shared instance,
   not the capability.

5. **Vector search eats its own dogfood.** `rag-api` provisions a pgvector
   *through the PaaS catalog*, exactly as a customer would. This avoids an
   "add sqlite-vec to Base" workstream and proves the catalog path works
   for first-party load. rag-api is the reference customer of its own
   product.

6. **Cross-tenant shared writes → NATS.** Leader election, pub/sub, and
   job queues use NATS (already in cluster). Not Postgres advisory locks,
   not a shared table. State that must be durable and per-tenant lives in
   that tenant's Base file; coordination *between* tenants is messaging.

7. **What this is NOT.** Not microservices. Not multi-DB-per-app. Not
   "each team picks its own database." One role, one answer: internal →
   Base; customer datastore → catalog product. Deviation needs a HIP, not
   a Slack thread.

---

## In-flight migration guardrails

| Workstream | From → To | Hard requirements |
|---|---|---|
| **esign** | Prisma `postgresql` → Base SQLite | Flip `datasource.provider` to `sqlite`. Re-emit migrations. Convert **29 enums** → `TEXT`+`CHECK`, `String[]` (`transports`) → JSON `TEXT`, `Json` cols → `TEXT`, `@db.Text` → `TEXT`. Per-`(org,user,project)` Base file. Grep-verify zero advisory locks / jsonb queries / array ops remain in app code. |
| **catalog** | UI reorg + bothub cutover | Group Postgres/Redis/DocDB/MongoDB/MariaDB/MySQL under **"Customer Databases"**; copy must read as *products*, not internal infra. Then: delete stale `bot-hub` Deployment (`hanzo` ns, live 122d), apply `market` Deployment from `~/work/hanzo/market/k8s/deployment.yaml` (`market` ns, `ghcr.io/hanzoai/market:latest`). |
| **platform** | **183** Drizzle migrations, dialect `pg` → `better-sqlite3` | Swap to `drizzle-orm/better-sqlite3`. Re-emit from SQLite dialect — drop `CREATE TYPE` / array / `jsonb` / `timestamptz`. Per-tenant Base file. Multi-day: ship what's clean this session, queue the rest with an honest count. Commit regenerated `_journal.json`. |

Definition of done for the Postgres-elimination program: `hanzo-sql`
shared instance deleted, operator Postgres CRD retained, no internal app
holds a Postgres connection string, all three apps on per-tenant Base.
