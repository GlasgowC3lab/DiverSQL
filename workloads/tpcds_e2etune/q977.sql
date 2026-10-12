WITH inv_agg AS (
    SELECT i.inv_warehouse_sk,
           SUM(i.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory i
    GROUP BY i.inv_warehouse_sk
)
SELECT
    cp.cp_department,
    w.w_state,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cs.cs_sales_price) AS total_sales_price,
    AVG(cs.cs_ext_discount_amt) AS avg_discount_amount,
    COALESCE(inv.total_inventory_qty, 0) AS total_inventory_qty
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN inv_agg inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
WHERE cp.cp_type = 'monthly'
  AND cp.cp_start_date_sk BETWEEN 2450990 AND 2451000
  AND cd.cd_gender = 'M'
  AND cd.cd_education_status = 'College'
GROUP BY cp.cp_department, w.w_state, inv.total_inventory_qty
HAVING SUM(cs.cs_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 50
