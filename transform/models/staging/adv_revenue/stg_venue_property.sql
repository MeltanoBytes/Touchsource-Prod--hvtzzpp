{{ config(
    schema = 'staging',
    materialized = 'view'
) }}

with dataset as (
    select * from {{ source('adv_revenue_lookuptables', 'venue_property') }}
)

select
    nullif(trim(venue_key), 'NULL')::varchar     as venue_key,
    nullif(trim(property_name), 'NULL')::varchar as property_name,
    nullif(trim(created_at), 'NULL')::varchar    as created_at
from dataset
