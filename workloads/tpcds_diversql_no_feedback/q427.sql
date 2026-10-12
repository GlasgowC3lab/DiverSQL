-- Goal: Compare total return amounts by reason with total sales amounts by year, combine them, duplicate the rows across a small set of years, and compute all‑dimension aggregates using CUBE.
WITH returns_agg AS (
    SELECT
        d.d_year AS year,
        r.r_reason_desc AS reason,
        SUM(cr.cr_return_amount) AS total_amount,
        CAST('return' AS varchar) AS source_type
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
    GROUP BY d.d_year, r.r_reason_desc
),
sales_agg AS (
    SELECT
        d.d_year AS year,
        CAST('Store Sales' AS varchar) AS reason,
        SUM(ss.ss_net_paid) AS total_amount,
        CAST('sales' AS varchar) AS source_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2022
    GROUP BY d.d_year
),
unioned AS (
    SELECT year, reason, total_amount, source_type FROM returns_agg
    UNION
    SELECT year, reason, total_amount, source_type FROM sales_agg
),
small_years AS (
    SELECT 2020 AS small_year UNION ALL SELECT 2021 UNION ALL SELECT 2022
),
crossed AS (
    SELECT
        s.small_year,
        u.year,
        u.reason,
        u.source_type,
        u.total_amount
    FROM small_years s
    CROSS JOIN unioned u
)
SELECT
    year,
    reason,
    source_type,
    SUM(total_amount) AS total_amount
FROM crossed
GROUP BY CUBE (year, reason, source_type)
LIMIT 100
