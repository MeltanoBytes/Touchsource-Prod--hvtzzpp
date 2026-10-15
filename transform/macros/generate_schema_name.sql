-- Every schema this project builds is prefixed with `meltano_` (e.g. core -> MELTANO_CORE).
--
-- Why: TouchSource's 5X dbt project builds the same models into STAGING / INTERMEDIATE / CORE
-- (in PROD_DB, as DBT_ROLE), and their Airbyte raw schemas in RAWDATA_DB (VISTAR_,
-- ADV_REVENUE_LOOKUPTABLES, AURORA_MYSQL_PROD, GA4_*) are owned by the same INGESTION_ROLE this
-- project runs as. Without the prefix, a model could replace an object their production flow
-- depends on. With it, this project can only ever write to MELTANO_* schemas.
--
-- This macro also overrides dbt's default so that elementary can write its test results in the
-- correct schema: a node whose meta sets `schema_name` uses that schema (prefixed too) instead
-- of appending to it.

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set config_meta = node.config.get('meta') -%}

    {%- if config_meta is mapping and config_meta.get('schema_name') is string -%}
        {%- set schema_name = config_meta.get('schema_name') -%}
    {%- elif custom_schema_name is none -%}
        {%- set schema_name = target.schema -%}
    {%- else -%}
        {%- set schema_name = custom_schema_name -%}
    {%- endif -%}

    {{ meltano_prefixed_schema(schema_name) }}

{%- endmacro %}


{% macro meltano_schema_prefix() -%}
    {%- set prefix = var('meltano_schema_prefix', 'meltano_') | trim | lower -%}
    {%- if not prefix.startswith('meltano') or not prefix.endswith('_') -%}
        {{ exceptions.raise_compiler_error(
            "meltano_schema_prefix must start with 'meltano' and end with '_' (got '" ~ prefix ~ "'). "
            ~ "It keeps this project out of TouchSource's production schemas.") }}
    {%- endif -%}
    {{ return(prefix) }}
{%- endmacro %}


{% macro meltano_prefixed_schema(schema_name) -%}
    {%- set prefix = meltano_schema_prefix() -%}
    {%- set name = schema_name | trim | lower -%}
    {%- if name.startswith(prefix) -%}
        {{ return(name) }}
    {%- endif -%}
    {{ return(prefix ~ name) }}
{%- endmacro %}
