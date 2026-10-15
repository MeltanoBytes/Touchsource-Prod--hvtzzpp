{{ config(
    schema = 'core',
    materialized = 'table'
) }}

{# ACCOUNT_UUID / SYSTEM_GROUP_UUID come straight from GA4 and are the keys the Touch
   Analytics row-level security rule filters on, so they are passed through untouched.
   The names are recovered from the current account / system_group rows, so they follow a
   rename and fill in for rows where GA4 sent no name. The raw GA4 name is the fallback for
   rows with no matching UUID (mobile, and touch rows synced before the UUIDs were added).
   A property's current name is used only while it still belongs to the row's account: a
   property reassigned to another account keeps its uuid, and its new owner's name must not
   appear on the previous owner's dashboard.
   Both lookups are deduplicated by UUID and left-joined, so they can neither drop nor
   duplicate a GA4 row. #}

with dataset as (
    select *
    from {{ ref('stg_ga4__event_stats') }}
),

accounts as (
    select
        account_id,
        account_uuid,
        account_display_name
    from {{ ref('stg_account') }}
    qualify row_number() over (partition by account_uuid order by account_updated_at desc nulls last) = 1
),

system_groups as (
    select
        sg.system_group_uuid,
        sg.system_group_display_name,
        owner.account_uuid as owner_account_uuid
    from {{ ref('stg_system_group') }} as sg
    left join accounts as owner
        on owner.account_id = sg.system_group_account_id
    qualify row_number() over (partition by sg.system_group_uuid order by sg.system_group_updated_at desc nulls last) = 1
)

select
    d.* exclude (account_name, system_group_name),
    coalesce(a.account_display_name, d.account_name) as account_name,
    coalesce(sg.system_group_display_name, d.system_group_name) as system_group_name
from dataset as d
left join accounts as a
    on a.account_uuid = d.account_uuid
left join system_groups as sg
    on sg.system_group_uuid = d.system_group_uuid
    and sg.owner_account_uuid = d.account_uuid
