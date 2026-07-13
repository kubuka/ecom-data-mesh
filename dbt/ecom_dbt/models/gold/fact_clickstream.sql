{{config(base_location_root = 'fact_clickstream')}}

with source_clickstream as (
    SELECT * from {{ref('silver_clickstream')}}
)

select
    event_id,
    {{ dbt_utils.generate_surrogate_key(['user_id']) }} AS customer_sk,
    user_id as customer_id,
    event_date::VARCHAR AS date_id,
    event_timestamp::TIMESTAMP_NTZ(6),
    event_type,
    device
FROM source_clickstream
    