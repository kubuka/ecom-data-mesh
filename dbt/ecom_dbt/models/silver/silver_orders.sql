{{config(
    base_location_root = 'silver_orders',
    unique_key='order_id',
    incremental_strategy='merge',
    partition_by='event_date'
)}}

WITH source_data AS (
    SELECT 
        order_id,
        customer_id,
        order_date,
        total_amount,
        currency,
        status,
        payment_method,
        event_date
    FROM {{ source('bronze', 'ext_core_system') }}
)

SELECT 
    order_id,
    customer_id,
    TRY_TO_TIMESTAMP(order_date)::TIMESTAMP_NTZ(6) AS order_date,
    total_amount,
    currency,
    status,
    payment_method,
    event_date
FROM source_data


{% if is_incremental() %}
    WHERE event_date > (SELECT MAX(event_date) FROM {{ this }})
{% endif %}