# Plugins

## Extractors

- **`tap-spreadsheets-s3` (matatika, `tap-spreadsheets-anywhere@v0.7.0`)** — S3 file tap, used as-is (no inherited per-pipeline variants); per-pipeline config goes in pipeline `properties`. Not on the public Meltano Hub; its lockfile `plugins/extractors/tap-spreadsheets-s3--matatika.lock` was built from the Meltano Cloud registry definition, so `meltano add` / `meltano lock` can't regenerate it locally.
  - `tables` is an array setting — as a pipeline property, give it as a JSON string.
  - `pattern` is a **regex on the full S3 key**, not a glob (backslashes doubled inside JSON).
  - `key_properties` is required; `vistar_s3` uses `[_smart_source_file, _smart_source_lineno]` so re-syncing a file upserts rather than duplicates.
  - `invalid_format_action: ignore` skips unreadable/malformed files instead of failing. Within a row, missing columns become null and surplus values land in `_smart_extra`.
  - `ignore_undefined_field_names: true` drops blank-header columns.

- **`tap-spreadsheets-sharepoint-app-registration` (matatika, `tap-spreadsheets-anywhere@v0.7.0`)** — SharePoint files with client-credentials auth (Entra app registration). Used by `adv_revenue_lookuptables`. Same table-spec shape as `tap-spreadsheets-s3`; `path` = `sharepoint://<site>/<library>/` (library root only), folder filtering via `pattern` regex on keys that begin with `/`.

## Loaders

- `target-postgres` (matatika) — backs the `Warehouse` data store.
- `target-snowflake` (meltanolabs, v0.20.2) — backs `Snowflake - SnowflakeIngestion`. Key-pair auth only.

## Transformers / files

- `dbt` (dbt-labs), `files-dbt`, `files-melty-ai` (matatika).
