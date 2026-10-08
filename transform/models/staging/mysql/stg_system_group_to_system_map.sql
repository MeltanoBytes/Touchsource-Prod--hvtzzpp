{{ config(
    schema = 'staging',
    materialized = 'view'
) }}

with dataset as (
    select
        system_group_uuid as sgts_system_group_uuid,
        system_uuid as sgts_system_uuid,
        created_at as sgts_created_at,
        updated_at as sgts_updated_at,
        deleted_at as sgts_deleted_at,
        created_by as sgts_created_by,
        updated_by as sgts_updated_by,
        _sdc_extracted_at
    from {{ source("rawdata_db", "system_group_to_system_map") }}
    where deleted_at is null
      -- FULL_TABLE replication: each run soft-deletes the previous copy.
      and _sdc_deleted_at is null
)

select * exclude(_sdc_extracted_at)
from dataset
qualify row_number() over(partition by sgts_system_group_uuid, sgts_system_uuid order by _sdc_extracted_at desc) = 1