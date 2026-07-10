with source_data as (
    SELECT
        $1 as raw_currency,
        $2 as raw_rate,
        $3 as raw_date,
        metadata$filename as file_name
    FROM @ECOM_DB.BRONZE.S3_EXCHANGE_STAGE
)

SELECT
    raw_currency::VARCHAR as currency,
    TRY_TO_DECIMAL(raw_rate,10,4) as exchange_rate_to_usd,
    TRY_TO_DATE(raw_date) as rate_date,
    file_name as source_file
FROM source_data