WITH daily_type_sales AS (
    SELECT
        cp.cp_type,
        cs.cs_sold_date_sk AS sold_date,
        SUM(cs.cs_net_paid) AS daily_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS daily_orders,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        COUNT(DISTINCT cd.cd_gender) AS gender_count,
        SUM(cs.cs_ext_discount_amt) AS total_discount
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
        MIN(daily_net_paid) OVER (PARTITION BY cp_type) AS min_daily_net,
        CUME_DIST() OVER (PARTITION BY cp_type ORDER BY daily_net_paid) AS cum_dist
    FROM daily_type_sales
)
SELECT
    cp_type,
    sold_date,
    daily_net_paid,
    daily_orders,
    distinct_customers,
    gender_count,
    total_discount,
    total_net_by_type,
    max_daily_net,
    min_daily_net,
    CASE WHEN cum_dist <= 0.25 THEN 'Bottom Quartile' WHEN cum_dist >= 0.75 THEN 'Top Quartile' ELSE 'Mid Quartile' END AS quartile_category,
    NTILE(3) OVER (PARTITION BY cp_type ORDER BY daily_net_paid DESC) AS net_paid_tertile
FROM with_totals
WHERE total_discount > 0
ORDER BY cp_type, cum_dist
