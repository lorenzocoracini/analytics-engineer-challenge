{{ config(
    materialized='table',
    tags=['marts', 'dimensions']
) }}

with source as (
  select 
    *
  from {{ ref('stg_loads') }}
),

pickup_locations as (
  select distinct
    pickup_city as city,
    pickup_state as state,
  from source
  where pickup_city is not null and pickup_state is not null
),

delivery_locations as (
  select distinct
    delivery_city as city,
    delivery_state as state,
  from source
  where delivery_city is not null and delivery_state is not null
),

-- UNION between distinct pickup and delivery locations to get all unique locations

all_locations as (
  select * from pickup_locations
  union
  select * from delivery_locations
),



final as (
  select 
    {{ dbt_utils.generate_surrogate_key(['city', 'state']) }} as location_id,
    city,
    state,
    current_timestamp as dbt_created_at
  from all_locations
  order by state, city
)

select * from final