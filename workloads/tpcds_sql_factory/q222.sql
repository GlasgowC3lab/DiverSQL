WITH site_metrics AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        d_open.d_date AS open_date,
        d_close.d_date AS close_date,
        COUNT(DISTINCT c.c_customer_id) AS customers_count,
        SUM(COALESCE(hd.hd_vehicle_count, 0)) AS total_vehicle_count,
        AVG(COALESCE(d_sales.d_year - c.c_birth_year, 0)) AS avg_customer_age_at_sale,
        date_diff('day', d_open.d_date, d_close.d_date) AS active_days
    FROM web_site ws
    JOIN date_dim d_open ON ws.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close ON ws.web_close_date_sk = d_close.d_date_sk
    LEFT JOIN customer c
        ON c.c_first_sales_date_sk BETWEEN ws.web_open_date_sk AND ws.web_close_date_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN date_dim d_sales ON c.c_first_sales_date_sk = d_sales.d_date_sk
    GROUP BY ws.web_site_id, ws.web_name, d_open.d_date, d_close.d_date
)
SELECT
    web_site_id,
    web_name,
    open_date,
    close_date,
    active_days,
    customers_count,
    total_vehicle_count,
    avg_customer_age_at_sale,
    RANK() OVER (ORDER BY total_vehicle_count DESC) AS vehicle_count_rank,
    PERCENT_RANK() OVER (ORDER BY customers_count DESC) AS customer_percentile,
    SUM(customers_count) OVER (ORDER BY open_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_customers
FROM site_metrics
ORDER BY vehicle_count_rank
LIMIT 50
