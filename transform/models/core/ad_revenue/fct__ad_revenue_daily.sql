{{ config(
    schema = 'core',
    materialized = 'table'
) }}

with enriched as (
    select * from {{ ref('int_ad_revenue_daily_enriched') }}
),

calc as (
    select
        *,
        (property_ownership_id is not null) as is_revshare_eligible,
        coalesce(commission_pct, 35.00) as screenverse_commission_pct
    from enriched
)

select
    * exclude (commission_pct),
    partner_revenue - partner_profit as platform_expense,
    round(partner_profit * screenverse_commission_pct / 100, 6) as screenverse_commission,
    round(partner_profit * (1 - screenverse_commission_pct / 100), 6) as ts_gross_revenue,
    round(partner_profit * (1 - screenverse_commission_pct / 100) * revshare / 100, 6) as revshare_owed_to_customer,
    round(partner_profit * (1 - screenverse_commission_pct / 100) * (1 - revshare / 100), 6) as ts_net_revenue
from calc
