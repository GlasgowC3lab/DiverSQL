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
        MAX(daily_net_paid) OVER (PARTITION BY cp_type) AS max_daily_net,
        MIN(daily_net_paid) OVER (PARTITION BY cp_type) AS min_daily_net
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
    max_daily_net,
    min_daily_net,
    CASE WHEN daily_net_paid = max_daily_net THEN 'Peak Day' WHEN daily_net_paid = min_daily_net THEN 'Low Day' ELSE 'Normal' END AS day_category,
    NTILE(4) OVER (PARTITION BY cp_type ORDER BY daily_net_paid DESC) AS net_paid_quartile
FROM with_totals
WHERE daily_net_paid IS NOT NULL
ORDER BY cp_type, sold_date
