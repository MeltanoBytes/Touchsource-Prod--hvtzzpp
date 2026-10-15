{{ config(
    schema = 'staging',
    materialized = 'view'
) }}

with dataset as (
    select
        id as system_id,
        uuid as system_uuid,
        display_name as system_display_name,
        salesforce_id_val as system_salesforce_id_val,
        mac_address as system_mac_address,
        resolution as system_resolution,
        hidden as is_system_hidden,
        network_type as system_network_type,
        directory_number as system_directory_number,
        created_at as system_created_at,
        updated_at as system_updated_at,
        deleted_at as system_deleted_at,
        created_by as system_created_by,
        updated_by as system_updated_by,
        _sdc_deleted_at
    from {{ source("rawdata_db", "system") }} 
)

select * exclude(_sdc_deleted_at)
from dataset
where _sdc_deleted_at is null