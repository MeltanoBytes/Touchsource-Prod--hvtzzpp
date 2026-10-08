{{ config(
    schema = 'staging',
    materialized = 'view'
) }}

with dataset as (
    select * from {{ source('adv_revenue_lookuptables', 'property_ownership') }}
)

select
    to_number(nullif(trim(id), 'NULL'), 38, 0)              as id,
    nullif(trim(property_name), 'NULL')::varchar            as property_name,
    nullif(trim(account_name), 'NULL')::varchar             as account_name,
    to_number(nullif(trim(revshare), 'NULL'), 38, 2)        as revshare,
    to_date(nullif(trim(effective_start), 'NULL'))          as effective_start,
    to_date(nullif(trim(effective_end), 'NULL'))            as effective_end,
    to_boolean(nullif(trim(is_current), 'NULL'))            as is_current,
    nullif(trim(notes), 'NULL')::varchar                    as notes,
    nullif(trim(created_at), 'NULL')::varchar               as created_at
from dataset
