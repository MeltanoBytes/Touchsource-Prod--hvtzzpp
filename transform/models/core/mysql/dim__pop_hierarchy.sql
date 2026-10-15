{{ config(
    materialized = 'table',
    schema = 'core'
) }}

-- One row per media player (system) per property (system group), with its account and
-- every system / property / account attribute core.proof_of_play exposes.
-- core.proof_of_play (a view) joins plays to this table, so dashboard filters built on it
-- always offer exactly the values the charts can show.
-- first_played_at / last_played_at are null for systems that have never played; use
-- last_played_at to keep dead systems out of the filter dropdowns.

with plays as (
    select
        pop_system_id,
        min(pop_created_at) as first_played_at,
        max(pop_created_at) as last_played_at
    from {{ ref('fct__proof_of_play') }}
    group by 1
),

hierarchy as (
    select distinct
        a.account_id,
        a.account_uuid,
        a.account_display_name,
        a.account_created_at,
        a.account_updated_at,
        a.account_deleted_at,
        a.salesforce_account_id,
        sg.system_group_id,
        sg.system_group_uuid,
        sg.system_group_display_name,
        sg.system_group_created_at,
        sg.system_group_created_by,
        sg.system_group_updated_at,
        sg.system_group_deleted_at,
        sg.system_group_time_zone,
        case
            when sg.system_group_monarch_location = '7 Gauss Way' then '7 Gauss Way, CA'
            when sg.system_group_monarch_location = 'CO' then 'Colorado, CO'
            when sg.system_group_monarch_location = 'Arcadia CA' then 'Arcadia, CA'
            else sg.system_group_monarch_location
        end as system_group_monarch_location,
        sg.system_group_static_map_longitude,
        sg.system_group_static_map_latitude,
        sg.system_group_online_expires,
        sg.system_group_zip_code,
        zc."ISO3166-2" as system_group_iso3166_2_code,
        zc.city as system_group_city,
        zc.state as system_group_state,
        s.system_id,
        s.system_uuid,
        s.system_display_name,
        s.system_created_at,
        s.system_updated_at,
        s.system_deleted_at
    from {{ ref('stg_system') }} as s
    inner join {{ ref('stg_system_group_to_system_map') }} as sgts
        on sgts.sgts_system_uuid = s.system_uuid
    inner join {{ ref('stg_system_group') }} as sg
        on sg.system_group_uuid = sgts.sgts_system_group_uuid
    inner join {{ ref('stg_account') }} as a
        on a.account_id = sg.system_group_account_id
    left join {{ ref('zip_codes') }} as zc
        on sg.system_group_zip_code = zc.zip
)

select
    h.*,
    country.state_id,
    country.state_name,
    country.state_code,
    country.iso_3166_2_code,
    plays.first_played_at,
    plays.last_played_at
from hierarchy as h
left join {{ ref('country_codes') }} as country
    on trim(split(h.system_group_monarch_location, ',')[1]) = country.state_code
left join plays
    on plays.pop_system_id = h.system_id
