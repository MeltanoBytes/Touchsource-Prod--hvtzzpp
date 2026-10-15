{% macro ga4_optional_column(relation, column_name, data_type='varchar') -%}
    {#-
        Selects a GA4 custom-dimension column if it exists on the relation, otherwise a typed
        NULL aliased to the same quoted name. This lets the GA4 staging models union the
        mobile and touch sources even when one connector has a dimension the other doesn't,
        and keeps them working before a connector sync has created a newly added column.
    -#}
    {%- set quoted = '"' ~ (column_name | upper) ~ '"' -%}
    {%- if not execute -%}
        {{ return(quoted) }}
    {%- endif -%}
    {%- set existing = adapter.get_columns_in_relation(relation) | map(attribute='name') | map('upper') | list -%}
    {%- if (column_name | upper) in existing -%}
        {{ return(quoted) }}
    {%- else -%}
        {{ return('cast(null as ' ~ data_type ~ ') as ' ~ quoted) }}
    {%- endif -%}
{%- endmacro %}
