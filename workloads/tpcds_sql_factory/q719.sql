WITH daily_type_sales AS (
    SELECT
        cp.cp_type,
        cs.cs_sold_date_sk AS sold_date,
        SUM(cs.cs_net_paid) AS daily_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS daily_orders,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        COUNT(DISTINCT cd.cd_gender) AS gender_count,
        SUM(cs.cs_ext_discount_amt) AS daily_discount_total
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY cp.cp_type, cs.cs_sold_date_sk
), with_totals AS (
    SELECT
        *,
        SUM(daily_net_paid) OVER (PARTITION BY cp_type) AS total_net_by_type,
        ROW_NUMBER() OVER (PARTITION BY cp_type ORDER BY sold_date DESC) AS rev_day_rank
    FROM daily_type_sales
)
SELECT
    cp_type,
    sold_date,
    daily_net_paid,
    daily_orders,
    distinct_customers,
    gender_count,
    daily_discount_total,
    CASE WHEN rev_day_rank = 1 THEN 'Latest Day' ELSE 'Prior Day' END AS day_position,
    SUM(daily_net_paid) OVER (PARTITION BY cp_type ORDER BY sold_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
    PERCENT_RANK() OVER (PARTITION BY cp_type ORDER BY daily_net_paid DESC) AS net_paid_percentile
FROM with_totals
WHERE daily_net_paid > 0
ORDER BY cp_type, sold_date
