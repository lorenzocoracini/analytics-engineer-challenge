{{ config(
    materialized='table',
    tags=['semantic', 'dimensions']
) }}

with source as (
  select 
    carrier_name,
    vip_carrier
  from {{ ref('stg_loads') }}
),

carriers as (
  select distinct
    {{ dbt_utils.generate_surrogate_key(['carrier_name']) }} as carrier_id,
    trim(carrier_name) as carrier_name,
    vip_carrier,
    current_timestamp as dbt_created_at
  from source
  where carrier_name is not null
  order by carrier_name
)

select * from carriers