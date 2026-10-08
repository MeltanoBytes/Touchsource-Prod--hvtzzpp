{{ config(
    schema = 'staging',
    materialized = 'view'
) }}

with dataset as (
    select
        id as account_id,
        uuid as account_uuid,
        display_name as account_display_name,
        salesforce_id_val as salesforce_account_id,
        require_2fa as is_account_required_2fa,
        created_at as account_created_at,
        updated_at as account_updated_at,
        deleted_at as account_deleted_at,
        created_by as account_created_by,
        updated_by as account_updated_by,
        _sdc_deleted_at
    from {{ source("rawdata_db", "account") }}  
)
select * exclude(_sdc_deleted_at)
from dataset
where _sdc_deleted_at is null
