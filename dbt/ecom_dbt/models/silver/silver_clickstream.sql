with raw_json as (
    SELECT
        $1 AS json_payload,
        metadata$filename as file_name
    FROM @ECOM_DB.BRONZE.S3_CLICKSTREAM_STAGE

),

flattened as (
    SELECT
        f.value as event_obj,
        r.file_name
    FROM raw_json r,
    LATERAL FLATTEN(input => r.json_payload) f
)

SELECT
    event_obj:event_id::VARCHAR as event_id,
    event_obj:user_id::VARCHAR as user_id,
    event_obj:event_type::VARCHAR as event_type,
    TRY_TO_TIMESTAMP(event_obj:timestamp::VARCHAR) as event_timestamp,
    TRY_TO_DATE(event_obj:event_date::VARCHAR) as event_date,
    event_obj:device::VARCHAR as device,
    file_name as source_file
FROM flattened