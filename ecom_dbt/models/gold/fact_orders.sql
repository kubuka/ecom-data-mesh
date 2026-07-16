{{ config(
    base_location_root = 'fact_orders',
    unique_key='order_id',
    incremental_strategy='merge'
) }}


WITH orders AS (
    SELECT * FROM {{ ref('silver_orders') }})

SELECT 
    o.order_id,
    {{ dbt_utils.generate_surrogate_key(['o.customer_id']) }} AS customer_sk, --połączenie do dim_customer
    CAST(o.order_date AS DATE)::VARCHAR as date_id, --połączenie do dim_date
    {{ dbt_utils.generate_surrogate_key(['o.order_date::DATE', 'o.currency']) }} as rate_sk, --połączenie do dim_exchange_rates,
    o.customer_id,
    o.order_date,
    o.status,
    o.payment_method,
    o.currency,
    o.total_amount AS original_amount,
    o.event_date
FROM orders o

{% if is_incremental() %}
    WHERE o.event_date > (SELECT MAX(event_date) FROM {{ this }})
{% endif %}

