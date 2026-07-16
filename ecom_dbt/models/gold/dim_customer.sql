{{ config(
    base_location_root='dim_customer',
    unique_key='customer_id',
    incremental_strategy='merge'
) }}

WITH today_orders AS (
    SELECT DISTINCT customer_id::VARCHAR AS customer_id
    FROM {{ ref('silver_orders') }} so
    {% if is_incremental() %}
    WHERE so.event_date > (SELECT MAX(t.loaded_at) FROM {{ this }} t)
    {% endif %}
),

today_clickstream AS (
    SELECT DISTINCT user_id::VARCHAR AS customer_id
    FROM {{ ref('silver_clickstream') }} sc
    {% if is_incremental() %}
    WHERE sc.event_date > (SELECT MAX(t.loaded_at) FROM {{ this }} t)
    {% endif %}
),


today_customers AS (
    SELECT 
        COALESCE(o.customer_id, c.customer_id) AS customer_id,
        CASE WHEN o.customer_id IS NOT NULL THEN TRUE ELSE FALSE END AS has_orders_today,
        CASE WHEN c.customer_id IS NOT NULL THEN TRUE ELSE FALSE END AS has_clickstream_today
    FROM today_orders o
    FULL OUTER JOIN today_clickstream c 
        ON o.customer_id = c.customer_id
),


final_customers AS (
    SELECT 
        tc.customer_id,
        {% if is_incremental() %}
        (tc.has_orders_today OR COALESCE(dc.has_orders, FALSE)) AS has_orders, -- ma order today or ma order wczesniej
        (tc.has_clickstream_today OR COALESCE(dc.has_clickstream, FALSE)) AS has_clickstream
    FROM today_customers tc
    LEFT JOIN {{ this }} dc ON tc.customer_id = dc.customer_id
        {% else %}
        tc.has_orders_today AS has_orders,
        tc.has_clickstream_today AS has_clickstream
    FROM today_customers tc
        {% endif %} -- te warunki tutaj do pierwszego stworzenia sa potrzebne
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
    CURRENT_TIMESTAMP(6)::DATE AS loaded_at
FROM final_customers

--Takie fikumiku muszę tutaj zrobić bo dane takie dziwne są. Znaczy no, sam je takie zrobiłem...
-- działa to tak ze pobiera klientow z dzisiaj z orders i clickstream
-- pozniej laczy je w jeden wiersz i w zaleznosci gdzie byl null to daje taka flage czynnosci
-- pozniej sprawdza czy jakis customer sie powtarza z poprzednimi wystapeniami z dimcustomers
-- jak tak to aktualizuje falsy albo zostawia tak jak bylo
-- merge dokleja tych ktorych nie bylo albo zmienia tych co juz byli