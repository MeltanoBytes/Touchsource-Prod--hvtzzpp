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
- **Runs via:** `script: meltano run tap-spreadsheets-s3 target-snowflake --state-id-suffix vistar-s3-full` — the suffix keeps this pipeline's incremental state separate from any other pipeline using the same tap/target pair. (Was `vistar-s3` until 2026-10-08: that state had been advanced to 2026-10-05 by an earlier run whose data was later dropped, so the first platform run skipped 21 revenue files. A new suffix starts clean from `start_date`; rows merge on `_smart_source_file` + `_smart_source_lineno`, so already-loaded files are not duplicated.)
- **Schedule:** manual only (intentionally unscheduled while this is a test).
- **Timeout / retries:** 36000s (10h) / 0.
- **Incremental behaviour:** files are picked up by S3 last-modified time, oldest first; first run starts from `2026-01-01T00:00:00Z` (full history, matching Airbyte's: billing from 2026-01, revenue from 2026-02-27), then from the latest synced file's timestamp in state.
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

