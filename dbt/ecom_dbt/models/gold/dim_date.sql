{{config(base_location_root = 'dim_date',
materialized='table')}}

WITH date_spine AS (
    SELECT DATEADD(day, ROW_NUMBER() OVER (ORDER BY NULL) - 1, '2024-01-01')::TIMESTAMP_NTZ(6) AS date_day
    FROM TABLE(GENERATOR(ROWCOUNT => 2557)) --7lat od 2024
)

select
    CAST(date_day::DATE as VARCHAR) as date_id,
    date_day,
    DAYNAME(date_day) as day_name,
    MONTHNAME(date_day) as month_name,
    YEAR(date_day) as year,
    QUARTER(date_day) as quarter
FROM date_spine