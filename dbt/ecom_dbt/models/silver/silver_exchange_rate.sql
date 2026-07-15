{{config(
    base_location_root = 'silver_exchange_rates',
    incremental_strategy='merge',
    unique_key=['rate_date', 'target_currency'],
    partition_by='event_date'
)}}

with source_data as (
    SELECT
        raw_currency,
        raw_rate,
        raw_date,
        event_date
    FROM {{source('bronze','ext_exchange_rates')}}
)

SELECT
    raw_currency::VARCHAR as currency,
    TRY_TO_DECIMAL(raw_rate,15,4) as exchange_rate_to_usd,
    TRY_TO_DATE(raw_date) as rate_date,
    event_date,
FROM source_data

{% if is_incremental() %}
    WHERE event_date > (SELECT MAX(event_date) FROM {{ this }})
{% endif %}