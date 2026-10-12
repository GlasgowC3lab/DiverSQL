WITH agg_sales AS (
    SELECT
        cs.cs_ship_mode_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales_price,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_ext_discount_amt > 500
      AND cs.cs_quantity BETWEEN 40 AND 80
      AND cs.cs_wholesale_cost < 80
    GROUP BY cs.cs_ship_mode_sk
    HAVING SUM(cs.cs_net_profit) > 1000
), ranked_sales AS (
    SELECT
        cs_ship_mode_sk,
        total_profit,
        total_sales_price,
        avg_discount,
        sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY cs_ship_mode_sk ORDER BY total_profit DESC) AS rn
    FROM agg_sales
)
SELECT
    sm.sm_type,
    sm.sm_carrier,
    rs.total_profit,
    rs.total_sales_price,
    rs.avg_discount,
    rs.sales_cnt,
    (SELECT AVG(s_tax_percentage) FROM store) AS avg_store_tax_pct,
    (SELECT COUNT(*) FROM web_page wp WHERE wp.wp_rec_start_date > DATE '2022-01-01') AS recent_web_pages
FROM ranked_sales rs
JOIN ship_mode sm ON rs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE rs.rn = 1
ORDER BY rs.total_profit DESC
LIMIT 20
