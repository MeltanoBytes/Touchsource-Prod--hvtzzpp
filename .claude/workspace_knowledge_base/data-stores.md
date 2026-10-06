# Data stores

- **Warehouse** — `target-postgres--matatika`. Workspace default data store **and** state store.
- **Snowflake - SnowflakeIngestion** — `target-snowflake--meltanolabs`. Credentials configured in Meltano Cloud. Target schema is set per pipeline via `Snowflake - SnowflakeIngestion.default_target_schema` (e.g. `vistar_s3` → `raw_vistar`).
