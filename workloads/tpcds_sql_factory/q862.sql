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
        SUM(daily_net_paid) OVER (PARTITION BY cp_type) AS total_net_by_type,
        AVG(daily_net_paid) OVER (PARTITION BY cp_type) AS avg_daily_net,
        RANK() OVER (PARTITION BY cp_type ORDER BY daily_net_paid DESC) AS net_rank
    FROM daily_type_sales
)
SELECT
    cp_type,
    sold_date,
    daily_net_paid,
    daily_orders,
    distinct_customers,
    gender_count,
    total_net_by_type,
    avg_daily_net,
    net_rank,
    CASE WHEN net_rank = 1 THEN 'Top Day' ELSE '' END AS top_day_flag,
    NTILE(5) OVER (PARTITION BY cp_type ORDER BY daily_net_paid) AS net_paid_quintile
FROM with_totals
WHERE daily_net_paid BETWEEN 1000 AND 50000
ORDER BY cp_type, net_rank
