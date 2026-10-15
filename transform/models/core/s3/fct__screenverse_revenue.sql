{{ config(
    schema = 'core',
    materialized = 'table'
) }}

with dataset as (
    select *
    from {{ ref('stg_s3__screenverse_revenue') }}
)

select * from dataset
