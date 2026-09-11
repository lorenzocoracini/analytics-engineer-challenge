{{ config(
    materialized='table',
    tags=['semantic', 'dimensions']
) }}

with source as (
  select 
    shipper_name
  from {{ ref('stg_loads') }}
),

shippers as (
  select distinct
    {{ dbt_utils.generate_surrogate_key(['shipper_name']) }} as shipper_id,
    trim(shipper_name) as shipper_name,
    current_timestamp as dbt_created_at
  from source
  where shipper_name is not null
  order by shipper_name
)

select * from shippers