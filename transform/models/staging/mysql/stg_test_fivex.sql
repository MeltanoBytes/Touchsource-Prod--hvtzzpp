{{ config(
    schema = 'staging',
    materialized = 'view'
) }}

with dataset as (
    select
        id as test_fivex_id,
        name as test_fivex_name,
        created_at as test_fivex_created_at
    from {{ source("aurora_mysql_reference", "_test_fivex") }}
)

select * from dataset