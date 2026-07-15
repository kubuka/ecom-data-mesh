{{config(base_location_root = 'dim_exchange_rates')}}

with source_rates as (
    select * from {{ref('silver_exchange_rate')}}
)

select 
    {{dbt_utils.generate_surrogate_key(['rate_date','currency'])}} as rate_sk,
    rate_date::VARCHAR as date_id,
    rate_date, 
    currency,
    exchange_rate_to_usd,
    event_date
From source_rates sr

{% if is_incremental() %}
    WHERE sr.event_date > (SELECT MAX(event_date) FROM {{ this }})
{% endif %}