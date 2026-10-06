# Pipelines

## vistar_s3 (`pipelines/vistar_s3.yml`)

- **Why:** Test pipeline to evaluate how Meltano handles this data ingestion — the customer previously ran it on Airbyte.
- **What:** Loads Screenverse/Vistar CSV exports from S3 bucket `screenverse-touchsource-akfq43tzm3fc` into Snowflake schema `raw_vistar` (`Snowflake - SnowflakeIngestion` data store) via `tap-spreadsheets-s3` → `target-snowflake`.
  - `screenverse_revenue` ← `touchsource/revenue/**/*.csv.gz`
  - `screenverse_billing` ← `touchsource/billing/**/*-byhour.csv` and `*-byhour.csv.gz`
- **Where config lives:** all source/destination settings are pipeline `properties`, not `meltano.yml` (user preference — see `rules.md`):
  - `tap-spreadsheets-s3.tables` — single-line JSON string (array of table specs; explicit `"delimiter": ","` so the tap doesn't try to sniff it).
  - `tap-spreadsheets-s3._select: ["screenverse_revenue.*","screenverse_billing.*"]`.
  - `Snowflake - SnowflakeIngestion.default_target_schema: raw_vistar`, `.add_record_metadata: true`.
  - AWS credentials set on the pipeline in the Meltano Cloud UI.
- **Runs via:** `script: meltano run tap-spreadsheets-s3 target-snowflake --state-id-suffix vistar-s3` — the suffix keeps this pipeline's incremental state separate from any other pipeline using the same tap/target pair.
- **Schedule:** manual only (intentionally unscheduled while this is a test).
- **Timeout / retries:** 36000s (10h) / 2.
- **Incremental behaviour:** files are picked up by S3 last-modified time; first run starts from `2026-09-01T11:30:00Z`, then from the latest synced file's timestamp in state.
- **Transforms:** none.
