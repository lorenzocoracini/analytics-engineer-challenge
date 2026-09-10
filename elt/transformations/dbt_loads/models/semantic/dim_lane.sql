{{ config(
    materialized='table',
    tags=['semantic', 'dimensions']
) }}

with source as (
  select 
    *
  from {{ ref('int_locations_from_lane') }}
),

lanes as (
  select distinct
    {{ dbt_utils.generate_surrogate_key(['pickup_city', 'pickup_state', 'delivery_city', 'delivery_state']) }} as lane_id,    
    {{ dbt_utils.generate_surrogate_key(['pickup_city', 'pickup_state']) }} as source_location_id,    
    {{ dbt_utils.generate_surrogate_key(['delivery_city', 'delivery_state']) }} as target_location_id,    
    trim(pickup_city) || ',' || trim(pickup_state) || ' -> ' || trim(delivery_city) || ',' || trim(delivery_state) as lane_name,    
    mileage,    
    current_timestamp as dbt_created_at 
  from source
  where pickup_city is not null 
    and pickup_state is not null 
    and delivery_city is not null 
    and delivery_state is not null
    and mileage is not null
)

select * from lanes