-- Never GRANT or REVOKE from this project. Some copied models carry `grants` for TouchSource's
-- BI_ROLE (Superset); applying them would expose these Meltano-built objects to their
-- dashboards before cut-over. Access is granted deliberately at cut-over, not by a dbt run.

{% macro snowflake__apply_grants(relation, grant_config, should_revoke=True) -%}
    {%- if grant_config -%}
        {{ log("Skipping grants on " ~ relation ~ ": grants are disabled in this project.", info=true) }}
    {%- endif -%}
{%- endmacro %}
