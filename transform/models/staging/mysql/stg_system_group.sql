{{ config(
    schema = 'staging',
    materialized = 'view'
) }}

with dataset as (
    select
        id as system_group_id,
        uuid as system_group_uuid,
        parent_id as system_group_parent_id,
        display_name as system_group_display_name,
        salesforce_id_val as system_group_salesforce_id_val,
        created_at as system_group_created_at,
        updated_at as system_group_updated_at,
        deleted_at as system_group_deleted_at,
        created_by as system_group_created_by,
        updated_by as system_group_updated_by,
        account_id as system_group_account_id,
        path as system_group_path,
        level as system_group_level,
        --path_width as system_group_path_width,
        --path_speed as system_group_path_speed,
        --path_endmarker_size as system_group_path_endmarker_size,
        time_zone as system_group_time_zone,
        zip_code as system_group_zip_code,
        project_number as system_group_project_number,
        monarch_location as system_group_monarch_location,
        --path_color as system_group_path_color,
        --path_endmarker as system_group_path_endmarker,
        static_map_longitude as system_group_static_map_longitude,
        static_map_latitude as system_group_static_map_latitude,
        online_expires as system_group_online_expires,
       _sdc_deleted_at
    from {{ source("rawdata_db", "system_group") }} 
)

select * exclude(_sdc_deleted_at)
from dataset
where _sdc_deleted_at is null