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


## sp (`pipelines/sp.yml`)

- **Why:** Ad-ops want to start reporting on the venue screen inventory maintained by hand in SharePoint (file `ads_08_2026`). This pipeline lands that file in Snowflake so dbt can join it to `fct__ad_revenue_daily` (new core model in the dbt repo on branch `meltano-dev`).
- **What:** Reads 1 CSV from SharePoint site `Advertising`, library `Documents`, folder `ad_rev`, into Snowflake schema `raw_sp_meltano` via `tap-spreadsheets-sharepoint-app-registration` → `target-snowflake`. Stream: `ads_08_2026` (all columns as strings, `prefer_schema_as_string`).
- **Full refresh / overwrite (as `adv_revenue_lookuptables`):** `meltano run --full-refresh` ignores state so the file is re-read each run, and `Snowflake - SnowflakeIngestion.load_method: overwrite` replaces the table. `key_properties: []`.
- **Path gotcha (same as `adv_revenue_lookuptables`):** `path` is the drive root (`sharepoint://Advertising/Documents/`); folder is narrowed via `pattern` (`^/ad_rev/(.+/)?ads_08_2026\.csv$`). Keys the tap matches against start with `/`.
- **Secrets:** reuses the shared SharePoint app-registration credentials set on the workspace (`oauth_credentials.client_id`, `oauth_credentials.client_secret`, `oauth_credentials.tenant_id`).
- **Schedule:** manual only.
- **Timeout / retries:** 3600s / 0.

## ad_revenue_models (`pipelines/ad_revenue_models.yml`)

- **Why:** Migration off 5X — replaces the 5X workflow "Daily + Monthly Ad Revenue" (`dbt build --select +fct__ad_revenue_daily +fct__ad_revenue_monthly`), using the Meltano-landed raw data instead of Airbyte's.
- **What:** dbt only. Builds the ad-revenue lineage from `raw_vistar_meltano` (`vistar_s3`) and `raw_adv_revenue_lookuptables_meltano` (`adv_revenue_lookuptables`) into `RAWDATA_DB.MELTANO_STAGING` / `MELTANO_INTERMEDIATE` / `MELTANO_CORE` (`fct__ad_revenue_daily`, `fct__ad_revenue_monthly`), and runs the 3 `assert_property_ownership_*` tests. Never writes to TouchSource's production schemas — see `rules.md`.
- **Models:** copied from TouchSource's 5X dbt repo (`5X-nextgen-customer-repo-prod/5X-touchsource-dbt` @ `c113430`) into `transform/`. Changes vs the 5X repo: sources repointed to the Meltano schemas; Airbyte metadata columns swapped (`_ab_source_file_url` → `_smart_source_file`, `_ab_source_file_last_modified` → `_smart_source_last_modified`, `_airbyte_extracted_at` → `_sdc_extracted_at`, `_airbyte_raw_id` → `_smart_source_lineno`, `_ab_cdc_deleted_at` → `_sdc_deleted_at`); `source_file_last_modified` kept as the same UTC ISO text / `VARCHAR(16777216)`; `BI_ROLE` grant removed from `proof_of_play`.
- **Validated 2026-10-08 (read-only, nothing built):** compiled models inlined and compared with the 5X project's compiled models on the files both sides hold — monthly (2026-08 billing file, 1,591,799 rows) identical on every column; daily (2026-10-05 revenue file, 37,382 rows) identical except `partner_ecpm`, which Airbyte lands as NULL in every revenue file (222 files in 2026) and Meltano lands populated. The 3 tests pass.
- **Runs via:** `meltano invoke dbt build --select +fct__ad_revenue_daily +fct__ad_revenue_monthly` (the dbt plugin has no `build` command, so `invoke`). `TARGET_SNOWFLAKE_PASSWORD` is exported empty because the data store uses key-pair auth and the `files-dbt` profile reads it unconditionally.
- **Data store:** `Snowflake - SnowflakeIngestion` (explicit — otherwise the workspace default `Warehouse` would be used). `Snowflake - SnowflakeIngestion.schema: meltano_dbt` gives dbt its default schema (prefixed like everything else).
- **Schedule:** manual only. Run it outside the Airbyte sync windows on `INGESTION_WH` (≈00:10 UTC MySQL, ≈06:00 UTC Vistar). Chain with `triggered_by: [vistar_s3]` at cut-over (a pipeline fires after *any one* of its `triggered_by` pipelines completes, not all).
- **Before relying on the numbers:** `vistar_s3` has only landed 1 revenue file and 1 billing file (its `start_date` is 2026-09-15 and state has advanced). Backfill it (earlier `start_date` + one `--full-refresh` run) for history comparable to Airbyte's (from 2026-01 billing / 2026-02-27 revenue).
- **Timeout / retries:** 3600s / 0.
