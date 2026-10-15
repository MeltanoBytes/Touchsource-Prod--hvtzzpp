{{ config(
    schema = 'core',
    materialized = 'table'
) }}

with codes as (
    select *
    from {{ source("aurora_mysql_reference", "country_codes") }}  
)
select
    STATE_ID,
    STATE_NAME,
    STATE_CODE,
    ISO_3166_2_CODE
from codes

