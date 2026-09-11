{{ config(
    materialized='table',
    tags=['marts', 'facts']
) }}

with source as (
  select 
    *
  from {{ ref('stg_loads') }}
),

with_lane_id as (
  select 
    source.*,
    lane.lane_id
  from source
  left join {{ ref('dim_lane') }} lane
    on {{ dbt_utils.generate_surrogate_key(['source.pickup_city', 'source.pickup_state', 'source.delivery_city', 'source.delivery_state']) }} = lane.lane_id
),

with_carrier_id as (
  select 
    with_lane_id.*,
    carrier.carrier_id
  from with_lane_id
  left join {{ ref('dim_carrier') }} carrier
    on {{ dbt_utils.generate_surrogate_key(['with_lane_id.carrier_name']) }} = carrier.carrier_id
),

with_shipper_id as (
  select 
    with_carrier_id.*,
    shipper.shipper_id
  from with_carrier_id
  left join {{ ref('dim_shipper') }} shipper
    on {{ dbt_utils.generate_surrogate_key(['with_carrier_id.shipper_name']) }} = shipper.shipper_id
),

final as (
  select 
    loadsmart_id,
    quote_date,
    book_date,
    source_date,
    pickup_date,
    delivery_date,
    pickup_appointment_time,
    delivery_appointment_time,
    lane_id,
    carrier_id,
    shipper_id,
    book_price,
    source_price,
    pnl,
    mileage,
    equipment_type,
    sourcing_channel,
    carrier_rating,
    carrier_dropped_us_count,
    vip_carrier,
    carrier_on_time_to_pickup,
    carrier_on_time_to_delivery,
    carrier_on_time_overall,
    has_mobile_app_tracking,
    has_macropoint_tracking,
    has_edi_tracking,
    contracted_load,
    load_booked_autonomously,
    load_sourced_autonomously,
    load_was_cancelled,
    dbt_loaded_at
  from with_shipper_id
)

select * from final