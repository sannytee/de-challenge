SELECT
    CAST(TO_CHAR(date_trunc('day', date), 'YYYYMMDD') AS bigint) AS calendar_id,
    date AS calendar_date,
    CASE
        WHEN EXTRACT(ISODOW FROM date) = 1 THEN 7
        ELSE EXTRACT(ISODOW FROM date) - 1
    END AS day_of_week,
    CASE WHEN date_trunc('month', date) = date THEN true ELSE false END AS is_first_date_of_month,
    CASE WHEN date_trunc('month', date) + INTERVAL '1 month - 1 day' = date THEN true ELSE false END AS is_last_date_of_month,
    CASE WHEN date_trunc('quarter', date) = date THEN true ELSE false END AS is_first_date_of_quarter,
    CASE WHEN date_trunc('quarter', date) + INTERVAL '3 months - 1 day' = date THEN true ELSE false END AS is_last_date_of_quarter,
    CASE WHEN date_trunc('year', date) = date THEN true ELSE false END AS is_first_date_of_year,
    CASE WHEN date_trunc('year', date) + INTERVAL '1 year - 1 day' = date THEN true ELSE false END AS is_last_date_of_year,
    CASE
        WHEN EXTRACT(ISODOW FROM date) IN (1, 7) THEN false
        ELSE true
    END AS is_weekday,
    CAST(TO_CHAR(date, 'YYYYMM') AS integer) AS fiscal_period_id,
    CAST(TO_CHAR(date, 'YYYYIW') AS integer) AS fiscal_week_id
FROM
    generate_series('2020-01-01'::date, '2020-03-31'::date, '1 day') AS date -- date range can be changed to needs. for this project, we are using a small date range
