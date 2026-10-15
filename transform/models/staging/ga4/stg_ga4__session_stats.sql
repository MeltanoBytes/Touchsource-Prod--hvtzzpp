{{ config(
    schema = 'staging',
    materialized = 'view'
) }}

{%- set mobile = source('ga4_mobile_prod', 'session_stats') %}
{%- set touch = source('ga4_touch_prod', 'session_stats') %}

-- Explicit column lists (not select *) so the union stays aligned when the
-- mobile and touch connectors expose different custom dimensions.
-- ACCOUNT_UUID / SYSTEM_GROUP_UUID are the dashboard's row-level security keys.
-- GA4 caps a report at 9 dimensions. Counted from what the ga4_touch connector
-- requests today, event_stats (8) needs project number removed to fit both;
-- _ga4_sources.yml also declares system_group_name / system_uuid, which the
-- connector does not request and must not, or the reports exceed the cap. The
-- names and project number are optional here; the core models recover the names
-- from the account / system_group tables.
with dataset as (
    select
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _airbyte_meta,
        _airbyte_generation_id,
        property_id,
        {{ ga4_optional_column(mobile, 'CUSTOMUSER:ACCOUNT_NAME') }},
        "CUSTOMUSER:SYSTEM_NAME",
        {{ ga4_optional_column(mobile, 'CUSTOMUSER:PROJECT_NUMBER') }},
        {{ ga4_optional_column(mobile, 'CUSTOMUSER:SYSTEM_GROUP_NAME') }},
        {{ ga4_optional_column(mobile, 'CUSTOMUSER:ACCOUNT_UUID') }},
        {{ ga4_optional_column(mobile, 'CUSTOMUSER:SYSTEM_GROUP_UUID') }},
        {{ ga4_optional_column(mobile, 'CUSTOMUSER:SYSTEM_UUID') }},
        date,
        city,
        country,
        startdate,
        enddate,
        sessions,
        eventcount,
        averagesessionduration,
        userengagementduration,
        'mobile' as ga4_source
    from {{ mobile }}

    union all

    select
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _airbyte_meta,
        _airbyte_generation_id,
        property_id,
        {{ ga4_optional_column(touch, 'CUSTOMUSER:ACCOUNT_NAME') }},
        "CUSTOMUSER:SYSTEM_NAME",
        {{ ga4_optional_column(touch, 'CUSTOMUSER:PROJECT_NUMBER') }},
        {{ ga4_optional_column(touch, 'CUSTOMUSER:SYSTEM_GROUP_NAME') }},
        {{ ga4_optional_column(touch, 'CUSTOMUSER:ACCOUNT_UUID') }},
        {{ ga4_optional_column(touch, 'CUSTOMUSER:SYSTEM_GROUP_UUID') }},
        {{ ga4_optional_column(touch, 'CUSTOMUSER:SYSTEM_UUID') }},
        date,
        city,
        country,
        startdate,
        enddate,
        sessions,
        eventcount,
        averagesessionduration,
        userengagementduration,
        'touch' as ga4_source
    from {{ touch }}
)

select
    _airbyte_raw_id as session_raw_id,
    _airbyte_extracted_at as session_extracted_at,
    _airbyte_meta as session_meta,
    _airbyte_generation_id as session_generation_id,
    ga4_source,
    property_id as session_property_id,
    "CUSTOMUSER:ACCOUNT_NAME" as account_name,
    "CUSTOMUSER:ACCOUNT_UUID" as account_uuid,
    "CUSTOMUSER:SYSTEM_NAME" as system_name,
    "CUSTOMUSER:SYSTEM_GROUP_NAME" as system_group_name,
    "CUSTOMUSER:SYSTEM_GROUP_UUID" as system_group_uuid,
    "CUSTOMUSER:SYSTEM_UUID" as system_uuid,
    "CUSTOMUSER:PROJECT_NUMBER" as session_project_number,
    try_to_date(date, 'YYYYMMDD') as date,
    city as session_city,
    country as session_country,
    startdate as session_start_date,
    enddate as session_end_date,
    sessions::number as session_sessions,
    eventcount::number as session_event_count,
    averagesessionduration::float as session_avg_session_duration,
    userengagementduration::float as session_user_engagement_duration
from dataset
