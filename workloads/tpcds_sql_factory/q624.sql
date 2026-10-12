WITH cc_data AS (
    SELECT
        cc_zip AS zip,
        cc_tax_percentage AS tax_pct,
        cc_employees AS employees,
        cc_sq_ft AS sq_ft
    FROM call_center
    WHERE cc_zip IS NOT NULL
),
store_data AS (
    SELECT
        s_zip AS zip,
        s_tax_percentage AS tax_pct,
        s_number_employees AS employees,
        s_floor_space AS sq_ft
    FROM store
    WHERE s_zip IS NOT NULL
),
web_data AS (
    SELECT
        web_zip AS zip,
        web_tax_percentage AS tax_pct,
        0 AS employees,
        0 AS sq_ft
    FROM web_site
    WHERE web_zip IS NOT NULL
),
combined AS (
    SELECT * FROM cc_data
    UNION ALL
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
),
agg_zip AS (
    SELECT
        zip,
        SUM(employees) AS total_employees,
        SUM(sq_ft) AS total_sq_ft,
        AVG(tax_pct) AS avg_tax_pct
    FROM combined
    GROUP BY zip
)
SELECT
    zip,
    total_employees,
    total_sq_ft,
    avg_tax_pct,
    CASE WHEN avg_tax_pct > 7 THEN 'High Tax' ELSE 'Low Tax' END AS tax_category,
    (total_employees + total_sq_ft / 100.0) AS combined_metric,
    DENSE_RANK() OVER (ORDER BY (total_employees + total_sq_ft / 100.0) DESC) AS zip_rank
FROM agg_zip
WHERE total_employees > 0 OR total_sq_ft > 0
ORDER BY zip_rank
LIMIT 10
