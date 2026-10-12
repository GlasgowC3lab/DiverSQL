SELECT
    cp.cp_department,
    sm.sm_carrier,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_quantity), 0) AS profit_per_item,
    RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
  AND cp.cp_department IN ('Electronics', 'Clothing', 'Home')
  AND sm.sm_type = 'AIR'
  AND cs.cs_quantity > 0
GROUP BY cp.cp_department, sm.sm_carrier
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 10
