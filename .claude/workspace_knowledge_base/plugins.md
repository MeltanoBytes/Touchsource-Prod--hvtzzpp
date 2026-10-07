# Plugins

## Extractors

- **`tap-spreadsheets-s3` (matatika, `tap-spreadsheets-anywhere@v0.7.0`)** — S3 file tap, used as-is (no inherited per-pipeline variants); per-pipeline config goes in pipeline `properties`. Not on the public Meltano Hub; its lockfile `plugins/extractors/tap-spreadsheets-s3--matatika.lock` was built from the Meltano Cloud registry definition, so `meltano add` / `meltano lock` can't regenerate it locally.
  - `tables` is an array setting — as a pipeline property, give it as a JSON string.
  - `pattern` is a **regex on the full S3 key**, not a glob (backslashes doubled inside JSON).
  - `key_properties` is required; `vistar_s3` uses `[_smart_source_file, _smart_source_lineno]` so re-syncing a file upserts rather than duplicates.
  - `invalid_format_action: ignore` skips unreadable/malformed files instead of failing. Within a row, missing columns become null and surplus values land in `_smart_extra`.
  - `ignore_undefined_field_names: true` drops blank-header columns.

- **`tap-mysql` (matatika, `pipelinewise-tap-mysql@v2.0.0`)** — used by `aurora_mysql`. Added with `meltano add` against the Meltano Cloud catalog hub (`MELTANO_HUB_API_ROOT=<catalog>/api/workspaces/<id>` + `MELTANO_HUB_URL_AUTH`).
  - Stream IDs are `<database>-<table>` (e.g. `bronco_ciprod-account`) — use these in `_select` / `_metadata`.
  - Replication method is set per stream with `tap-mysql._metadata` (`replication-method`: `LOG_BASED` / `INCREMENTAL` / `FULL_TABLE`). `LOG_BASED` needs binlog privileges (`REPLICATION SLAVE`, `REPLICATION CLIENT`).
  - SSH tunnelling is done by the platform, not the tap: setting `ssh_tunnel.host` turns it on; `ssh_tunnel.private_key` must be base64-encoded.
  - Known quirk: the tap only enables TLS when `ssl` equals the *string* `'true'`, but Meltano passes the boolean setting as `true`, so `ssl: true` has no effect — the connection relies on the SSH tunnel for encryption in transit.

## Loaders

- `target-postgres` (matatika) — backs the `Warehouse` data store.
- `target-snowflake` (meltanolabs, v0.20.2) — backs `Snowflake - SnowflakeIngestion`. Key-pair auth only.

## Transformers / files

- `dbt` (dbt-labs), `files-dbt`, `files-melty-ai` (matatika).
