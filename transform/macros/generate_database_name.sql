-- Models always build in the target database (the Snowflake data store's database).
-- A `database=` config on a model would let it write outside the MELTANO_* schemas, so it is
-- rejected rather than honoured.

{% macro generate_database_name(custom_database_name=none, node=none) -%}
    {%- if custom_database_name is not none and (custom_database_name | trim | upper) != (target.database | upper) -%}
        {{ exceptions.raise_compiler_error(
            "Node '" ~ (node.unique_id if node else '?') ~ "' sets database '" ~ custom_database_name
            ~ "'. This project only builds in the target database (" ~ target.database ~ ").") }}
    {%- endif -%}
    {{ target.database }}
{%- endmacro %}
