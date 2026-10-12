SELECT
    store.s_store_id,
    store.s_store_name,
    CASE
        WHEN store.s_number_employees >= 252 THEN 'Large'
        WHEN store.s_number_employees >= 237 THEN 'Medium'
        ELSE 'Small'
    END AS employee_category,
    (store.s_floor_space * store.s_gmt_offset) / 6745675 AS adjusted_floor_space,
    date_dim.d_year - 1911 AS years_since_year,
    CONCAT(store.s_city, ', ', store.s_state) AS city_state,
    CASE
        WHEN date_dim.d_holiday = 'Y' THEN 'Holiday'
        ELSE 'Regular Day'
    END AS day_type
FROM store
JOIN date_dim
    ON store.s_closed_date_sk = date_dim.d_date_sk
WHERE date_dim.d_year = 1905
  AND store.s_tax_percentage < 0.03
