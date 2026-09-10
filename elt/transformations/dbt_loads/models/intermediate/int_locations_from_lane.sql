{{ config(
    materialized='view',
    tags=['intermediate']
) }}

with source as (
  select 
    loadsmart_id,
    lane,
    mileage
  from {{ ref('stg_loads') }}
),

parsed_lanes as (
  select 
    loadsmart_id,
    lane,    
    trim(split_part(split_part(lane, '->', 1), ',', 1)) as pickup_city,
    trim(split_part(split_part(lane, '->', 1), ',', 2)) as pickup_state,    
    trim(split_part(split_part(lane, '->', 2), ',', 1)) as delivery_city,
    trim(split_part(split_part(lane, '->', 2), ',', 2)) as delivery_state,
    mileage
  from source
)

select * from parsed_lanes