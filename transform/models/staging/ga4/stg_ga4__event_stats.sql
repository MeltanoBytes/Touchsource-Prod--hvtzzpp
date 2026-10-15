{{ config(
    schema = 'staging',
    materialized = 'view'
) }}

{%- set mobile = source('ga4_mobile_prod', 'event_stats') %}
{%- set touch = source('ga4_touch_prod', 'event_stats') %}

-- Explicit column lists (not select *) so the union stays aligned when the
-- mobile and touch connectors expose different custom dimensions. Mobile sends
-- searchTerm as a user property, touch sends it as an event parameter.
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
        eventname,
        {{ ga4_optional_column(mobile, 'CUSTOMUSER:ACCOUNT_NAME') }},
        "CUSTOMUSER:SYSTEM_NAME",
        {{ ga4_optional_column(mobile, 'CUSTOMUSER:PROJECT_NUMBER') }},
        {{ ga4_optional_column(mobile, 'CUSTOMUSER:SYSTEM_GROUP_NAME') }},
        {{ ga4_optional_column(mobile, 'CUSTOMUSER:ACCOUNT_UUID') }},
        {{ ga4_optional_column(mobile, 'CUSTOMUSER:SYSTEM_GROUP_UUID') }},
        date,
        startdate,
        enddate,
        eventcount,
        "CUSTOMEVENT:ROWDATA",
        "CUSTOMEVENT:LISTNAME",
        "CUSTOMUSER:SEARCHTERM" as search_term,
        'mobile' as ga4_source
    from {{ mobile }}

    union all

    select
        _airbyte_raw_id,
        _airbyte_extracted_at,
        _airbyte_meta,
        _airbyte_generation_id,
        property_id,
        eventname,
        {{ ga4_optional_column(touch, 'CUSTOMUSER:ACCOUNT_NAME') }},
        "CUSTOMUSER:SYSTEM_NAME",
        {{ ga4_optional_column(touch, 'CUSTOMUSER:PROJECT_NUMBER') }},
        {{ ga4_optional_column(touch, 'CUSTOMUSER:SYSTEM_GROUP_NAME') }},
        {{ ga4_optional_column(touch, 'CUSTOMUSER:ACCOUNT_UUID') }},
        {{ ga4_optional_column(touch, 'CUSTOMUSER:SYSTEM_GROUP_UUID') }},
        date,
        startdate,
        enddate,
        eventcount,
        "CUSTOMEVENT:ROWDATA",
        "CUSTOMEVENT:LISTNAME",
        "CUSTOMEVENT:SEARCHTERM" as search_term,
        'touch' as ga4_source
    from {{ touch }}
)

select
    _airbyte_raw_id as event_raw_id,
    _airbyte_extracted_at as event_extracted_at,
    _airbyte_meta as event_meta,
    _airbyte_generation_id as event_generation_id,
    ga4_source,
    property_id as event_property_id,
    eventname as event_name,
    "CUSTOMUSER:ACCOUNT_NAME" as account_name,
    "CUSTOMUSER:ACCOUNT_UUID" as account_uuid,
    "CUSTOMUSER:SYSTEM_NAME" as system_name,
    "CUSTOMUSER:SYSTEM_GROUP_NAME" as system_group_name,
    "CUSTOMUSER:SYSTEM_GROUP_UUID" as system_group_uuid,
    "CUSTOMUSER:PROJECT_NUMBER" as event_project_number,
    try_to_date(date, 'YYYYMMDD') as date,
    startdate as event_start_date,
    enddate as event_end_date,
    eventcount::number as event_count,
    "CUSTOMEVENT:ROWDATA" as event_row_data,
    "CUSTOMEVENT:LISTNAME" as event_list_name,
    search_term as event_search_term
from dataset
