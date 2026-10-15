{{ config(
    schema = 'staging',
    materialized = 'view'
) }}

with dataset as (
    select * from {{ source('adv_revenue_lookuptables', 'properties') }}
)

select
    nullif(trim(property_name), 'NULL')::varchar as property_name,
    nullif(trim(notes), 'NULL')::varchar         as notes,
    nullif(trim(created_at), 'NULL')::varchar    as created_at
from dataset
