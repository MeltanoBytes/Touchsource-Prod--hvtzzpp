{{ config(
    schema = 'staging',
    materialized = 'view'
) }}

with dataset as (
    select * from {{ source('vistar', 'screenverse_revenue') }}
),

-- Keep only the latest-loaded source file per date (Screenverse re-issues each
-- day across overlapping files; loading all versions duplicates the daily feed).
deduplicated as (
    select *
    from dataset
    qualify dense_rank() over (
        partition by try_to_date(date, 'YYYY-MM-DD')
        order by _smart_source_last_modified desc,
                 _smart_source_file desc
    ) = 1
),

collapsed as (
    select *
    from deduplicated
    qualify row_number() over (
        partition by
            _smart_source_file,
            {{ screenverse_row_hash() }}
        order by _sdc_extracted_at asc,
                 _smart_source_lineno asc
    ) = 1
)

select
    advertiser_name,
    ad_exchange,
    bidder,
    bidder_name,
    buyer,
    buyer_name,
    buy_type,
    creative_id,
    creative_name,
    try_to_date(date, 'YYYY-MM-DD') as date,
    deal,
    deal_id,
    global_city,
    hour_of_day::number as hour_of_day,
    impressions::float as impressions,
    month,
    network_name,
    partner_data_provider_revenue::float as partner_data_provider_revenue,
    partner_data_provider_revenue_ecpm::float as partner_data_provider_revenue_ecpm,
    partner_ecpm::float as partner_ecpm,
    partner_profit::number(38, 10) as partner_profit,
    partner_revenue::number(38, 10) as partner_revenue,
    partner_venue_id,
    {{ extract_venue_key('partner_venue_id') }} as venue_key,
    quarter,
    spots::number as spots,
    us_dma,
    us_state,
    us_zip,
    venue_name,
    venue_type,
    week,
    year(try_to_date(date, 'YYYY-MM-DD')) as year,
    -- Same text and type Airbyte produced (UTC ISO-8601, VARCHAR(16777216)), so the column is
    -- unchanged downstream.
    to_varchar(_smart_source_last_modified, 'YYYY-MM-DD"T"HH24:MI:SS.FF6"Z"')::varchar(16777216) as source_file_last_modified
from collapsed
-- Exclude malformed rows: a valid transaction always has a year, so 'None' marks junk.
where year <> 'None'
