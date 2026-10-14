# Data stores

- **Warehouse** — `target-postgres--matatika`. Workspace **state store** (`state_data_store`). Keep state here: a Snowflake state store fails with "Password was not given but private key is encrypted", because the encrypted key's passphrase isn't passed to the Snowflake state backend.
- **Snowflake - SnowflakeIngestion** — `target-snowflake--meltanolabs`. Workspace **default data store**. Credentials configured in Meltano Cloud (key-pair, encrypted key + passphrase). Target schema is set per pipeline via `Snowflake - SnowflakeIngestion.default_target_schema` (always a `*_meltano` schema).
