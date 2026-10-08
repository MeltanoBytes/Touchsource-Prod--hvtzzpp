{{ config(
    materialized = 'incremental',
    schema = 'core',
    unique_key = 'pop_id',
    incremental_strategy = 'merge',
    on_schema_change = 'append_new_columns',
    cluster_by = ['to_date(pop_created_at)'],
    post_hook = ["alter table {{ this }} suspend recluster"]
) }}

-- One row per play, play attributes only. System / property / account attributes are
-- joined at query time in the proof_of_play view, so a reassignment or rename applies to
-- historical plays without rebuilding this table.
-- Plays are insert-only in bronco, so each run merges only rows Meltano loaded since the
-- last run (with a 1-day overlap for rows from a sync that was still in progress).
-- New rows append in date order, so the table stays clustered without automatic
-- reclustering (suspended by the post_hook). Full refresh = one-off 2B-row sorted rebuild.

select
    pop_id,
    pop_system_id,
    pop_description,
    pop_host_url,
    pop_provider,
    pop_provider_name,
    pop_asset_url,
    pop_duration,
    pop_media_type,
    pop_start_of_play,
    pop_end_of_play,
    pop_created_at,
    pop_loop_id,
    pop_loop_name,
    pop_loop_mode,
    pop_impressions,
    pop_media_cost,
    pop_spots,
    pop_expires,
    pop_errors,
    pop_message,
    pop_http_status,
    case
        when pop_provider in ('pelican', 'slide_deck') or pop_provider is null then 'VCL/Slideshow'
        when pop_provider in ('peacock', 'nova') then 'Programmatic Content'
        when pop_provider = 'monarch' then 'Infotainment'
        else initcap(pop_provider)
    end as pop_provider_renamed,
    extract(hour from pop_end_of_play) as pop_end_of_play_hour,
    extract(hour from pop_created_at) as play_hour,
    pop_loaded_at
from {{ ref('stg_brood_proof_of_play') }}
{% if is_incremental() %}
where pop_loaded_at >= (select dateadd(day, -1, max(pop_loaded_at)) from {{ this }})
{% endif %}
