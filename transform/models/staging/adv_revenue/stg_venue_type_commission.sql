{{ config(
    schema = 'staging',
    materialized = 'view'
) }}

with dataset as (
    select * from {{ source('adv_revenue_lookuptables', 'venue_type_commission') }}
)

select
    nullif(trim(venue_type), 'NULL')::varchar             as venue_type,
    to_number(nullif(trim(commission_pct), 'NULL'), 38, 2) as commission_pct,
    nullif(trim(notes), 'NULL')::varchar                  as notes,
    nullif(trim(created_at), 'NULL')::varchar             as created_at
from dataset
