SELECT cp.cp_department,
       sm.sm_type AS ship_mode_type,
       COUNT(DISTINCT cs.cs_order_number) AS total_orders,
       SUM(cs.cs_net_profit) AS total_sales_profit,
       SUM(cr.cr_net_loss) AS total_returns_loss,
       (SUM(cs.cs_net_profit) - COALESCE(SUM(cr.cr_net_loss), 0)) AS net_profit_after_returns,
       AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
       SUM(cs.cs_quantity) AS total_quantity_sold,
       SUM(cr.cr_return_quantity) AS total_quantity_returned,
       CASE WHEN SUM(cs.cs_quantity) > 0 THEN SUM(cr.cr_return_quantity) * 100.0 / SUM(cs.cs_quantity) ELSE 0 END AS return_rate_percent
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    AND cs.cs_item_sk = cr.cr_item_sk
    AND cs.cs_warehouse_sk = cr.cr_warehouse_sk
WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
  AND cp.cp_type = 'monthly'
GROUP BY cp.cp_department, sm.sm_type
HAVING SUM(cs.cs_net_profit) > 10000
ORDER BY net_profit_after_returns DESC
LIMIT 20
