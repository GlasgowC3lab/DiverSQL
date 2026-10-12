WITH discount_data AS (
    SELECT
        sm.sm_type,
        d.d_quarter_name AS quarter,
        cs.cs_ext_discount_amt,
        cs.cs_ext_list_price,
        CASE
            WHEN cs.cs_ext_discount_amt >= 20 THEN 'High'
            WHEN cs.cs_ext_discount_amt >= 10 THEN 'Medium'
            ELSE 'Low'
        END AS discount_level,
        cd.cd_gender
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON cs.cs_ship_cdemo_sk = cd.cd_demo_sk
)
SELECT
    sm_type,
    quarter,
    discount_level,
    COUNT(*) AS orders,
    SUM(cs_ext_discount_amt) AS total_discount_amount,
    AVG(CASE WHEN cs_ext_list_price = 0 THEN NULL ELSE cs_ext_discount_amt / cs_ext_list_price END) AS avg_discount_pct,
    COUNT(DISTINCT cd_gender) AS gender_count,
    DENSE_RANK() OVER (PARTITION BY quarter ORDER BY SUM(cs_ext_discount_amt) DESC) AS discount_rank,
    SUM(COUNT(*)) OVER (PARTITION BY quarter) AS total_orders_quarter,
    (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (PARTITION BY quarter) AS pct_of_quarter_orders
FROM discount_data
GROUP BY sm_type, quarter, discount_level
ORDER BY quarter, discount_rank
