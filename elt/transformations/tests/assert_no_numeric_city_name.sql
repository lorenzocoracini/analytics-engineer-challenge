select 
  loadsmart_id,
  pickup_city,
  delivery_city
from {{ ref('stg_loads') }}
where 
  pickup_city ~ '[0-9]'
  or delivery_city ~ '[0-9]'