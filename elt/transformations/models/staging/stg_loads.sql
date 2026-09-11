{{ config(
    materialized='view',
    tags=['staging', 'loads']
) }}

with source as (
  select 
    *
  from {{ source('raw', 'loads_raw') }}
),

deduplicated as (
  select 
    *,
    row_number() over (
      partition by 
        quote_date,
        book_date,
        source_date,
        pickup_date,
        delivery_date,
        pickup_appointment_time,
        delivery_appointment_time,
        lane,
        equipment_type,
        sourcing_channel,
        carrier_name,
        shipper_name,
        book_price,
        source_price,
        pnl,
        mileage,
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
        load_was_cancelled
      order by loadsmart_id
    ) as rn
  from source
),

staging as (
  select 
    loadsmart_id,    
    quote_date::timestamp as quote_date,
    book_date::timestamp as book_date,
    source_date::timestamp as source_date,
    pickup_date::timestamp as pickup_date,
    delivery_date::timestamp as delivery_date,
    pickup_appointment_time::timestamp as pickup_appointment_time,
    delivery_appointment_time::timestamp as delivery_appointment_time,    
    trim(lane) as lane,
    trim(split_part(split_part(lane, '->', 1), ',', 1)) as pickup_city,
    trim(split_part(split_part(lane, '->', 1), ',', 2)) as pickup_state,    
    trim(split_part(split_part(lane, '->', 2), ',', 1)) as delivery_city,
    trim(split_part(split_part(lane, '->', 2), ',', 2)) as delivery_state,
    trim(equipment_type) as equipment_type,
    trim(sourcing_channel) as sourcing_channel,
    trim(carrier_name) as carrier_name,
    trim(shipper_name) as shipper_name,    
    book_price,
    source_price,
    pnl,
    mileage,    
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
    current_timestamp as dbt_loaded_at
  from deduplicated
  where rn = 1
)

select * from staging