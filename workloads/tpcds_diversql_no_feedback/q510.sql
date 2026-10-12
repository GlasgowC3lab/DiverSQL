WITH item_sales AS (
    SELECT 
        cs.cs_item_sk,
        d.d_year,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_item_sk, d.d_year
)
SELECT 
    cs.cs_order_number,
    d.d_date,
    i.i_product_name,
    sm.sm_code,
    w.w_warehouse_name,
    sr.sr_return_amt,
    r.r_reason_desc,
    isales.total_net_profit,
    RANK() OVER (PARTITION BY d.d_year ORDER BY isales.total_net_profit DESC) AS profit_rank,
    avg_price_sub.avg_price
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN item_sales isales ON isales.cs_item_sk = cs.cs_item_sk AND isales.d_year = d.d_year
CROSS JOIN LATERAL (
    SELECT AVG(cs2.cs_list_price) AS avg_price
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = cs.cs_item_sk
      AND cs2.cs_sold_date_sk = cs.cs_sold_date_sk
) AS avg_price_sub
WHERE d.d_year = 2001
  AND sm.sm_code = 'AIR'
  AND r.r_reason_desc LIKE '%warranty%'
  AND cs.cs_ext_wholesale_cost > 1000
ORDER BY d.d_year, profit_rank
LIMIT 100
