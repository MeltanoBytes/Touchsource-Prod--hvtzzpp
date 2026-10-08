{% macro extract_venue_key(venue_id, ivs_prefix='34792') %}
    case
        when startswith({{ venue_id }}, '{{ ivs_prefix }}-')
            then {{ venue_id }}
        when contains({{ venue_id }}, '-')
            then split_part(regexp_replace({{ venue_id }}, '^[Pp]', ''), '-', 1)
        when regexp_like({{ venue_id }}, '^[0-9]+$')
            then '{{ ivs_prefix }}-' || {{ venue_id }}
        else {{ venue_id }}
    end
{% endmacro %}
