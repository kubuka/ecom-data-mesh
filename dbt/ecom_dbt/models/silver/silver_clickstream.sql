{{config(
    base_location_root = 'silver_clickstream',
    incremental_strategy='append',
    partition_by='event_date'
)}}

with raw_json as (
    SELECT
        value AS json_payload,
        event_date
    FROM {{source('bronze','ext_clickstream')}}

),

flattened as (
    SELECT
        f.value as event_obj,
        r.event_date
    FROM raw_json r,
    LATERAL FLATTEN(input => r.json_payload) f
)

SELECT
    event_obj:event_id::VARCHAR as event_id,
    event_obj:user_id::VARCHAR as user_id,
    event_obj:event_type::VARCHAR as event_type,
    (event_obj:timestamp::VARCHAR)::TIMESTAMP_NTZ(6) AS event_timestamp,
    event_obj:device::VARCHAR as device,
    event_date
FROM flattened 

{% if is_incremental() %}
    WHERE event_date > (SELECT MAX(event_date) FROM {{ this }})
{% endif %}