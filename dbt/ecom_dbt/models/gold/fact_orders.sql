{{ config(
    base_location_root = 'fact_orders'
) }}


WITH orders AS (
    SELECT * FROM {{ ref('silver_orders') }}
),
rates AS (
    SELECT * FROM {{ ref('silver_exchange_rate') }}
)

SELECT 
    o.order_id,
    o.customer_id,
    CAST(o.order_date AS TIMESTAMP_NTZ(6)) AS order_date,
    o.status,
    o.payment_method,
    o.currency,
    o.total_amount AS original_amount,
    r.exchange_rate_to_usd,
    TRY_CAST(o.total_amount AS DECIMAL(10,2)) / NULLIF(r.exchange_rate_to_usd, 0) AS amount_usd
FROM orders o
LEFT JOIN rates r 
    ON o.currency = r.currency 
    AND o.order_date::DATE = r.rate_date