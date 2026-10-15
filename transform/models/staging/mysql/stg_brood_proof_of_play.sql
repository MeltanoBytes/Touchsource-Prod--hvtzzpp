{{ config(
    schema = 'staging',
    materialized = 'view'
) }}

with dataset as (
    select
        id as pop_id,
        system_id as pop_system_id,
        system_uuid pop_system_uuid,
        description as pop_description,
        remote_address as pop_remote_address,
        host_url as pop_host_url,
        user_agent as pop_user_agent,
        provider as pop_provider,
        provider_name as pop_provider_name,
        asset_url as pop_asset_url,
        duration as pop_duration,
        media_type as pop_media_type,
        start_of_play as pop_start_of_play,
        end_of_play as pop_end_of_play,
        loop_id as pop_loop_id,
        loop_name as pop_loop_name,
        loop_mode as pop_loop_mode,
        created_at as pop_created_at,
        -- Vistar/Nova PoP response metrics (aviary DEV-11958). NULL = no provider fire.
        pop_impressions,
        pop_media_cost,
        pop_spots,
        pop_expires,
        pop_errors,
        pop_message,
        pop_http_status,
        -- When Meltano loaded the row (UTC). _sdc_extracted_at is TIMESTAMP_NTZ; keep the
        -- TIMESTAMP_TZ type the Airbyte load timestamp had (incremental watermark).
        to_timestamp_tz(to_varchar(_sdc_extracted_at, 'YYYY-MM-DD HH24:MI:SS.FF9') || ' +0000', 'YYYY-MM-DD HH24:MI:SS.FF9 TZHTZM') as pop_loaded_at,
        _sdc_deleted_at
    from {{ source('rawdata_db', '_brood_proof_of_play') }} 
)

select * exclude(_sdc_deleted_at)
from dataset 
where _sdc_deleted_at is null
