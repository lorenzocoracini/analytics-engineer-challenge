{{ config(
  materialized = 'view',
  tags = ['staging', 'loads']
) }}

WITH source AS (

  SELECT
    *
  FROM
    {{ source(
      'raw',
      'loads_raw'
    ) }}
),
deduplicated AS (
  SELECT
    *,
    ROW_NUMBER() over (
      PARTITION BY quote_date,
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
      ORDER BY
        loadsmart_id
    ) AS rn
  FROM
    source
),
staging AS (
  SELECT
    loadsmart_id,
    quote_date :: TIMESTAMP AS quote_date,
    book_date :: TIMESTAMP AS book_date,
    source_date :: TIMESTAMP AS source_date,
    pickup_date :: TIMESTAMP AS pickup_date,
    delivery_date :: TIMESTAMP AS delivery_date,
    pickup_appointment_time :: TIMESTAMP AS pickup_appointment_time,
    delivery_appointment_time :: TIMESTAMP AS delivery_appointment_time,
    TRIM(lane) AS lane,
    TRIM(SPLIT_PART(SPLIT_PART(lane, '->', 1), ',', 1)) AS pickup_city_raw,
    TRIM(SPLIT_PART(SPLIT_PART(lane, '->', 1), ',', 2)) AS pickup_state,
    TRIM(SPLIT_PART(SPLIT_PART(lane, '->', 2), ',', 1)) AS delivery_city_raw,
    TRIM(SPLIT_PART(SPLIT_PART(lane, '->', 2), ',', 2)) AS delivery_state,
    TRIM(equipment_type) AS equipment_type,
    TRIM(sourcing_channel) AS sourcing_channel,
    TRIM(carrier_name) AS carrier_name,
    TRIM(shipper_name) AS shipper_name,
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
    load_booked_autonomously,
    load_sourced_autonomously,
    load_was_cancelled,
    CURRENT_TIMESTAMP AS dbt_loaded_at
  FROM
    deduplicated
  WHERE
    rn = 1
),
clean_locations AS (
  SELECT
    loadsmart_id,
    quote_date,
    book_date,
    source_date,
    pickup_date,
    delivery_date,
    pickup_appointment_time,
    delivery_appointment_time,
    lane,
    {{ clean_city_name(
      'pickup_city_raw',
      'pickup_state',
      'delivery_state'
    ) }} AS pickup_city,
    pickup_state,
    {{ clean_city_name(
      'delivery_city_raw',
      'delivery_state',
      'pickup_state'
    ) }} AS delivery_city,
    delivery_state,
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
    load_booked_autonomously,
    load_sourced_autonomously,
    load_was_cancelled,
    dbt_loaded_at
  FROM
    staging
)
SELECT
  *
FROM
  clean_locations
