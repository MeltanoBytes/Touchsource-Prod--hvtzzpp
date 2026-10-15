{{ config(
    schema = 'core',
    materialized = 'table'
) }}
with ownership as (
    select * from {{ ref('stg_property_ownership') }}
)

select
    id as property_ownership_id,
    property_name,
    account_name,
    revshare,
    effective_start,
    effective_end,
    (effective_end is null) as is_current
from ownership
