with source_data as (
    SELECT
        $1:order_id::VARCHAR AS order_id,
        $1:customer_id::INTEGER AS customer_id,
        TRY_TO_TIMESTAMP($1:order_date::VARCHAR) AS order_date,
        $1:total_amount::DECIMAL(10,2) AS total_amount,
        $1:currency::VARCHAR AS currency,
        $1:status::VARCHAR AS status,
        $1:payment_method::VARCHAR AS payment_method,
        metadata$filename AS file_name
    FROM @ECOM_DB.BRONZE.S3_CORE_SYSTEM_STAGE
)
SELECT * FROM source_data