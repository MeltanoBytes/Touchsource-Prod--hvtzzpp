{{ config(
    materialized = 'table',
    schema = 'core'
) }}

-- Distinct content attributes per property, with first/last play timestamps.
-- Backs the Media Type / Content Source / Content Description filters on the
-- Proof Of Play dashboard. Built once per dbt run instead of once per dashboard load.
-- account_uuid is kept so the dashboard's row-level security rule still applies, and
-- account/system group names are kept so the filters can cascade from Account / Property Name.
-- Use last_played_at as the pre-filter time column in Superset.
-- Aggregates per system first (narrow scan of the play table), then joins the small
-- hierarchy, which gives the same result as grouping core.proof_of_play directly.

with plays as (
    select
        pop_system_id,
        pop_media_type,
        pop_provider_renamed,
        pop_description,
        min(pop_created_at) as first_played_at,
        max(pop_created_at) as last_played_at,
        count(*) as total_plays
    from {{ ref('fct__proof_of_play') }}
    group by 1, 2, 3, 4
)

select
    h.account_uuid,
    h.account_display_name,
    h.system_group_display_name,
    p.pop_media_type,
    p.pop_provider_renamed,
    p.pop_description,
    min(p.first_played_at) as first_played_at,
    max(p.last_played_at) as last_played_at,
    sum(p.total_plays) as total_plays
from plays as p
inner join {{ ref('dim__pop_hierarchy') }} as h
    on h.system_id = p.pop_system_id
group by 1, 2, 3, 4, 5, 6
