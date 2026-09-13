{%- macro clean_city_name(city_col, state_col, other_state_col) -%}
  coalesce(
    case 
      when {{ city_col }} ~ '[0-9]' then 
        coalesce(
          (select distinct {{ city_col }}
           from staging alt
           where alt.{{ state_col }} = staging.{{ state_col }}
             and alt.{{ other_state_col }} = staging.{{ other_state_col }}
             and alt.{{ city_col }} !~ '[0-9]'
           limit 1),
          (select distinct {{ city_col }}
           from staging alt
           where alt.shipper_name = staging.shipper_name
             and alt.{{ state_col }} = staging.{{ state_col }}
             and alt.{{ city_col }} !~ '[0-9]'
           limit 1),
          staging.{{ state_col }}
        )
      else {{ city_col }}
    end,
    {{ city_col }}
  )
{%- endmacro -%}