# Workspace rules

- **Pipeline settings are managed in the Meltano Cloud UI** (since 2026-10-16). Don't re-add them to `pipelines/*.yml`. A setting absent from the file keeps its UI value on deploy, but a UI save of a pipeline strips its `properties:` block from the file (the write-back commit moves the values into the UI), so a file-defined property only lasts until the next UI edit. Keep settings in the UI and record their expected values in `pipelines.md`. Never put pipeline settings in `meltano.yml` `config`.
- **Use default plugins; don't create inherited per-pipeline plugins** (e.g. `tap-x-<client>`) unless there's a concrete need. One plugin, configured per pipeline.
- **Pipeline YAML shape:** a `script:` running `meltano run <tap> <target> --state-id-suffix <pipeline-name>` (not `actions:`), single-line JSON for array/object properties, followed by the pipeline's dbt steps (`meltano run dbt:deps`, `meltano invoke dbt build --select …`). Selection and record-metadata settings are set in the UI.
- **dbt only ever writes to `MELTANO_*` schemas.** TouchSource's production dbt (5X, `DBT_ROLE`, `PROD_DB`) builds the same model names into `STAGING` / `INTERMEDIATE` / `CORE`, and their Airbyte raw schemas in `RAWDATA_DB` are owned by the `INGESTION_ROLE` our data store uses. So `transform/macros/generate_schema_name.sql` prefixes every schema with `meltano_` and fails the run if the prefix is changed to anything else; `generate_database_name.sql` rejects `database=` overrides; `apply_grants.sql` makes grants a no-op (no `BI_ROLE` / Superset access before cut-over). Don't remove or bypass these until cut-over is agreed with TouchSource.
- **Proof-of-play (MySQL) and GA4 dbt models stay disabled** (`enable_mysql_models` / `enable_ga4_models` vars, default `false`) until their Meltano pipelines have landed data. `fct__proof_of_play` is a 2B-row incremental build that would compete with the Airbyte syncs on the shared `INGESTION_WH`.
- **Footprint check after every run.** Airbyte and Meltano share the `INGESTION_USER` login, so identify our sessions as those that touched a `*_MELTANO` object, then confirm nothing else in those sessions wrote anywhere. Expected result: only `PUT_FILES` / `REMOVE_FILES` on the loader's own user-stage paths (`@~/target-snowflake/<stream>-<uuid>/`). Any other row is a problem. Query history in `INFORMATION_SCHEMA` covers the last 7 days.

  ```sql
  with q as (select * from table(rawdata_db.information_schema.query_history_by_user(
               user_name => 'INGESTION_USER', end_time_range_start => dateadd(hour, -24, current_timestamp()), result_limit => 10000))),
  ours as (select distinct session_id from q where query_text ilike '%_meltano%')
  select q.query_type, count(*) n, any_value(left(q.query_text, 160)) example_sql
  from q join ours using (session_id)
  where q.query_type not in ('SELECT','SHOW','DESCRIBE','USE','ALTER_SESSION','UNKNOWN','LIST_FILES','GET_FILES','BEGIN_TRANSACTION','COMMIT','ROLLBACK','EXPLAIN')
    and q.query_text not ilike '%_meltano%'
  group by 1;
  ```
