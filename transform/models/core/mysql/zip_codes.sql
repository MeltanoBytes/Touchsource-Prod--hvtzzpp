{{ config(
    schema = 'core',
    materialized = 'table'
) }}

with zip_codes as (
    select *
    from {{ source("aurora_mysql_reference", "zip_codes") }}  
)
select
    CITY,
    STATE,
    ZIP,
    "ISO3166-2"
from zip_codes

