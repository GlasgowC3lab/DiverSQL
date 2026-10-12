WITH daily_type_sales AS (
    SELECT
        cp.cp_type,
        cs.cs_sold_date_sk AS sold_date,
        SUM(cs.cs_net_paid) AS daily_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS daily_orders,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        COUNT(DISTINCT cd.cd_gender) AS gender_count
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cp.cp_type, cs.cs_sold_date_sk
), with_totals AS (
    SELECT
        *,
        SUM(daily_net_paid) OVER (PARTITION BY cp_type) AS total_net_by_type
    FROM daily_type_sales
)
SELECT
    cp_type,
    sold_date,
    daily_net_paid,
    daily_orders,
    distinct_customers,
    gender_count,
    AVG(daily_net_paid) OVER (PARTITION BY cp_type ORDER BY sold_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3_days,
    SUM(daily_net_paid) OVER (PARTITION BY cp_type ORDER BY sold_date) AS cumulative_net_paid,
    DENSE_RANK() OVER (ORDER BY total_net_by_type DESC) AS type_sales_rank,
    CASE
        WHEN daily_net_paid > 10000 THEN 'Peak'
        WHEN daily_net_paid BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_level
FROM with_totals
WHERE sold_date IS NOT NULL
ORDER BY cp_type, sold_date
