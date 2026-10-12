WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        AVG(inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    w.w_state AS warehouse_state,
    cd.cd_marital_status,
    cd.cd_gender,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    inv_agg.avg_inventory_on_hand
FROM web_sales ws
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN inv_agg
    ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451170
  AND cd.cd_purchase_estimate > 500
  AND w.w_state IN ('CA', 'NY')
GROUP BY
    w.w_state,
    cd.cd_marital_status,
    cd.cd_gender,
    inv_agg.avg_inventory_on_hand
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
