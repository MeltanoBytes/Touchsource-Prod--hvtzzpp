{{ config(
    materialized = 'view',
    schema = 'core'
) }}

{# Meltano copy: the BI_ROLE grant from the 5X project is removed, so Superset cannot see this
   view before cut-over. Grants are disabled project-wide (macros/apply_grants.sql). #}

{# Plays (fct__proof_of_play, incremental) joined to the current system / property / account
   attributes (dim__pop_hierarchy) at query time, so nightly runs only load new plays and a
   reassignment or rename shows up on historical plays straight away.
   Same columns, names and order as the former table, so the Superset dataset, filters and
   RLS rule keep working. Date filters prune fct__proof_of_play, which is clustered by play date.
   grants: PROD_DB's future grants cover tables only, not views, so BI_ROLE is granted here. #}

select
  p.pop_id,
  p.pop_description,
  h.system_group_id,
  h.system_group_uuid,
  h.system_group_display_name,
  h.system_id,
  h.system_uuid,
  h.system_display_name,
  h.system_created_at,
  h.system_updated_at,
  h.system_deleted_at,
  h.system_group_created_at,
  h.system_group_created_by,
  h.system_group_updated_at,
  h.system_group_deleted_at,
  h.account_id,
  h.account_uuid,
  h.account_display_name,
  h.account_created_at,
  h.account_updated_at,
  h.account_deleted_at,
  h.salesforce_account_id,
  h.system_group_time_zone,
  h.system_group_monarch_location,
  h.system_group_static_map_longitude,
  h.system_group_static_map_latitude,
  h.system_group_online_expires,
  p.pop_host_url,
  p.pop_provider,
  p.pop_provider_name,
  p.pop_asset_url,
  p.pop_duration,
  p.pop_media_type,
  p.pop_start_of_play,
  p.pop_end_of_play,
  p.pop_created_at,
  p.pop_loop_id,
  p.pop_loop_name,
  p.pop_loop_mode,
  p.pop_impressions,
  p.pop_media_cost,
  p.pop_spots,
  p.pop_expires,
  p.pop_errors,
  p.pop_message,
  p.pop_http_status,
  p.pop_provider_renamed,
  p.pop_end_of_play_hour,
  h.system_group_zip_code,
  h.system_group_iso3166_2_code,
  h.system_group_city,
  h.system_group_state,
  h.state_id,
  h.state_name,
  h.state_code,
  h.iso_3166_2_code,
  -- Systems with at least one play, across all accounts (same value as the former
  -- full-table count). Read from the small hierarchy table, not the 2B-row play table.
  (select count(distinct system_id) from {{ ref('dim__pop_hierarchy') }} where first_played_at is not null) as total_systems,
  p.play_hour
from {{ ref('fct__proof_of_play') }} as p
inner join {{ ref('dim__pop_hierarchy') }} as h
  on h.system_id = p.pop_system_id
