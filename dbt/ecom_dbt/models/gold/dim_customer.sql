{{config(base_location_root = 'dim_customer')}}

WITH orders_customers AS (
    SELECT DISTINCT customer_id::VARCHAR AS customer_id,
    event_date
    FROM {{ ref('silver_orders') }}
    WHERE customer_id IS NOT NULL
),

clickstream_users AS (
    SELECT DISTINCT user_id::VARCHAR AS customer_id
    FROM {{ ref('silver_clickstream') }}
    WHERE user_id IS NOT NULL
),


all_customers AS (
    SELECT 
        COALESCE(o.customer_id, c.customer_id) AS customer_id,
        CASE WHEN o.customer_id IS NOT NULL THEN TRUE ELSE FALSE END AS has_orders,
        CASE WHEN c.customer_id IS NOT NULL THEN TRUE ELSE FALSE END AS has_clickstream,
        o.event_date
    FROM orders_customers o
    FULL OUTER JOIN clickstream_users c 
        ON o.customer_id = c.customer_id
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} AS customer_sk,
    customer_id,
    has_orders,
    has_clickstream,
    CASE 
        WHEN has_orders AND has_clickstream THEN 'both_systems'
        WHEN has_orders THEN 'core_system_only'
        ELSE 'clickstream_only'
    END AS customer_profile,
    CURRENT_TIMESTAMP(6) AS loaded_at,
    event_date
FROM all_customers ac

{% if is_incremental() %}
    WHERE ac.event_date > (SELECT MAX(event_date) FROM {{ this }})
{% endif %}