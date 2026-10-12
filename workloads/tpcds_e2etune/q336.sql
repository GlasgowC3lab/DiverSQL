WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    p.p_promo_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    inv_agg.total_inventory_qty,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amount
FROM web_sales ws
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inv_agg
  ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE p.p_discount_active = 'Y'
  AND ca.ca_state = 'CA'
  AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2451000
GROUP BY w.w_warehouse_name,
         p.p_promo_name,
         inv_agg.total_inventory_qty
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
