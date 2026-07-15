{{config(base_location_root = 'fact_clickstream')}}

with source_clickstream as (
    SELECT * from {{ref('silver_clickstream')}}
)

select
    c.event_id,
    {{ dbt_utils.generate_surrogate_key(['c.user_id']) }} AS customer_sk,
    c.user_id as customer_id,
    c.event_date::VARCHAR AS date_id,
    c.event_timestamp,
    c.event_type,
    c.device,
    c.event_date
FROM source_clickstream c

{% if is_incremental() %}
    WHERE c.event_date > (SELECT MAX(t.event_date) FROM {{ this }} t)
{% endif %}
    