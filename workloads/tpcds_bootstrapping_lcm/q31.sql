WITH daily_sales AS (
    SELECT
        ss.ss_store_sk,
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_tax) AS total_tax,
        COUNT(*) AS sales_cnt,
        AVG(t.t_hour) AS avg_hour
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2022
    GROUP BY ss.ss_store_sk, d.d_date_sk, d.d_date, d.d_year, d.d_month_seq
),
top_daily_sales AS (
    SELECT
        ds.*,
        ROW_NUMBER() OVER (PARTITION BY ds.ss_store_sk ORDER BY ds.total_sales DESC) AS rn
    FROM daily_sales ds
)
SELECT
    s.s_store_name,
    ds.d_date,
    ds.total_sales,
    ds.total_tax,
    ds.sales_cnt,
    ds.avg_hour,
    d_closed.d_date AS store_closed_date,
    COUNT(DISTINCT wp.wp_web_page_id) AS pages_created,
    COUNT(DISTINCT wp_access.wp_web_page_id) AS pages_accessed,
    d_access.d_day_name AS access_day_name
FROM top_daily_sales ds
JOIN store s ON ds.ss_store_sk = s.s_store_sk
JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = ds.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
LEFT JOIN web_page wp_access ON wp_access.wp_access_date_sk = ds.d_date_sk
WHERE ds.rn <= 3
GROUP BY
    s.s_store_name,
    ds.d_date,
    ds.total_sales,
    ds.total_tax,
    ds.sales_cnt,
    ds.avg_hour,
    d_closed.d_date,
    d_access.d_day_name
ORDER BY ds.total_sales DESC
LIMIT 100
