{{ config(
    schema = 'intermediate',
    materialized = 'view'
) }}

with revenue as (
    select * from {{ ref('stg_s3__screenverse_billing') }}
),

venue_property as (
    select venue_key, 
           property_name
    from {{ ref('stg_venue_property') }}
),

properties as (
    select property_name, 
           notes as property_notes
    from {{ ref('stg_properties') }}
),

property_ownership as (
    select property_ownership_id, 
           property_name, 
           account_name, 
           revshare, 
           effective_start, 
           effective_end
    from {{ ref('dim__property_ownership') }}
),

venue_type_commission as (
    select venue_type,
           commission_pct
    from {{ ref('stg_venue_type_commission') }}
)

select
    revenue.*,
    venue_property.property_name,
    properties.property_notes,
    property_ownership.property_ownership_id,
    property_ownership.account_name,
    property_ownership.revshare,
    venue_type_commission.commission_pct
from revenue
left join venue_property
    on venue_property.venue_key = revenue.venue_key
left join properties
    on properties.property_name = venue_property.property_name
left join property_ownership
    on property_ownership.property_name = venue_property.property_name
    and revenue.date between property_ownership.effective_start
                          and coalesce(property_ownership.effective_end, date '9999-12-31')
left join venue_type_commission
    on venue_type_commission.venue_type = revenue.venue_type
