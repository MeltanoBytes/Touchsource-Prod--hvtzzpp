# Pipelines

## vistar_s3 (`pipelines/vistar_s3.yml`)

- **Why:** Test pipeline to evaluate how Meltano handles this data ingestion — the customer previously ran it on Airbyte.
- **What:** Loads Screenverse/Vistar CSV exports from S3 bucket `screenverse-touchsource-akfq43tzm3fc` into Snowflake schema `raw_vistar_meltano` (`Snowflake - SnowflakeIngestion` data store) via `tap-spreadsheets-s3` → `target-snowflake`.
  - `screenverse_revenue` ← `touchsource/revenue/**/*.csv.gz`
  - `screenverse_billing` ← `touchsource/billing/**/*-byhour.csv` and `*-byhour.csv.gz`
- **Where config lives:** all source/destination settings are pipeline `properties`, not `meltano.yml` (user preference — see `rules.md`):
  - `tap-spreadsheets-s3.tables` — single-line JSON string (array of table specs; explicit `"delimiter": ","` so the tap doesn't try to sniff it).
  - `tap-spreadsheets-s3._select: ["screenverse_revenue.*","screenverse_billing.*"]`.
  - `Snowflake - SnowflakeIngestion.default_target_schema: raw_vistar_meltano`, `.add_record_metadata: true`.
  - AWS credentials set on the pipeline in the Meltano Cloud UI.
- **Runs via:** `script: meltano run tap-spreadsheets-s3 target-snowflake --state-id-suffix vistar-s3` — the suffix keeps this pipeline's incremental state separate from any other pipeline using the same tap/target pair.
- **Schedule:** manual only (intentionally unscheduled while this is a test).
- **Timeout / retries:** 36000s (10h) / 0.
- **Incremental behaviour:** files are picked up by S3 last-modified time; first run starts from `2026-09-15T00:00:00Z`, then from the latest synced file's timestamp in state.
- **Transforms:** none.

## aurora_mysql (`pipelines/aurora_mysql.yml`)

- **Why:** Migration off Airbyte — replaces Airbyte connection `aurora_mysql_prod` (MySQL CDC → Snowflake schema `aurora_mysql_prod`, daily). Built on dev first to validate before cut-over.
- **What:** Replicates 5 tables from the production Aurora MySQL database `bronco_ciprod` into Snowflake schema `raw_aurora_mysql_meltano` via `tap-mysql` → `target-snowflake`. All columns selected (Airbyte selected all columns too).
  - `_brood_proof_of_play`, `account`, `system`, `system_group` — `LOG_BASED` (binlog), the equivalent of Airbyte CDC. First run does a full initial sync, then reads the binlog from the saved position.
  - `system_group_to_system_map` — `FULL_TABLE` (no primary key; Airbyte did full refresh/overwrite). Each run appends a fresh copy and soft-deletes the previous copy via `ACTIVATE_VERSION` (`_sdc_deleted_at` set) — filter `_sdc_deleted_at is null` downstream.
  - Deletes on `LOG_BASED` tables are soft deletes (`_sdc_deleted_at`), matching Airbyte's "Soft delete" CDC mode.
- **Connectivity:** host `production-aurora-cluster.cluster-cbyizl1ico48.us-east-1.rds.amazonaws.com:3306`, user `fivex`, through SSH bastion `ec2-54-172-246-184.compute-1.amazonaws.com:22` as `fivetran` (same as Airbyte). Meltano Cloud opens the tunnel itself when `tap-mysql.ssh_tunnel.host` is set.
- **Secrets (set in Meltano Cloud UI, never in git):** `tap-mysql.password`, `tap-mysql.ssh_tunnel.private_key` (**base64-encoded** PEM — the platform base64-decodes it).
- **Runs via:** `meltano run tap-mysql target-snowflake --state-id-suffix aurora-mysql`.
- **Schedule:** manual only on dev (Airbyte ran every 24h). Add a `schedule` at cut-over.
- **Timeout / retries:** 36000s (10h) / 0.
- **Transforms:** none.

