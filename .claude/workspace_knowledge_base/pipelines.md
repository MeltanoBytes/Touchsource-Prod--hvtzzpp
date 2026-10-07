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

## adv_revenue_lookuptables (`pipelines/adv_revenue_lookuptables.yml`)

- **Why:** Migration off Airbyte — replaces Airbyte connection `Adv_revenue_lookuptables` (SharePoint CSVs → Snowflake schema `Adv_revenue_lookuptables`, daily full refresh). These are the advertising-revenue lookup tables maintained by hand in SharePoint.
- **What:** Reads 4 CSVs from SharePoint site `Advertising`, library `Documents`, folder `Ad Rev Lookup/Touchsource_ad_rev_lookuptables_views`, into Snowflake schema `raw_adv_revenue_lookuptables_meltano` via `tap-spreadsheets-sharepoint-app-registration` → `target-snowflake`. Streams: `properties`, `property_ownership`, `venue_property`, `venue_type_commission` (all columns as strings, `prefer_schema_as_string`).
- **Full refresh / overwrite (as Airbyte):** `meltano run --full-refresh` ignores state so every file is re-read each run, and `Snowflake - SnowflakeIngestion.load_method: overwrite` replaces each table. `key_properties: []`.
- **Path gotcha:** `path` must be the **drive root** (`sharepoint://Advertising/Documents/`) — with a sub-folder in `path` the tap doubles the folder when opening files (404). Narrow to the folder with `pattern` instead. Keys the tap matches against start with `/` (e.g. `/Ad Rev Lookup/.../properties.csv`).
- **Secrets (set in Meltano Cloud UI, never in git):** `oauth_credentials.client_id`, `oauth_credentials.client_secret`, `oauth_credentials.tenant_id` (same Entra app registration Airbyte used).
- **Validated locally 2026-10-07:** 484 / 486 / 630 / 8 rows.
- **Schedule:** manual only on dev (Airbyte ran every 24h). Add a `schedule` at cut-over.
- **Timeout / retries:** 3600s / 0.
- **Transforms:** none.

