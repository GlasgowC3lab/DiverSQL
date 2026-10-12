WITH order_agg AS (
  SELECT
    ws.ws_order_number,
    c.c_customer_id,
    w.w_warehouse_sk,
    w.w_warehouse_name,
    SUM(ws.ws_ext_sales_price) AS order_sales,
    SUM(ws.ws_quantity) AS order_qty,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
    MAX(i.inv_quantity_on_hand) AS max_qty_on_hand
  FROM tpcds.web_sales ws
  JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN tpcds.inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND w.w_country = 'United States'
    AND ws.ws_ext_tax > 30
    AND ws.ws_ext_sales_price BETWEEN 1000 AND 15000
    AND ws.ws_ship_mode_sk IS NOT NULL
    AND ws.ws_order_number IS NOT NULL
    AND ws.ws_quantity > 0
  GROUP BY ws.ws_order_number, c.c_customer_id, w.w_warehouse_sk, w.w_warehouse_name
),
warehouse_summary AS (
  SELECT
    o.w_warehouse_sk,
    o.w_warehouse_name,
    COUNT(DISTINCT o.ws_order_number) AS num_orders,
    SUM(o.order_sales) AS sum_sales,
    AVG(o.order_sales) AS avg_order_sales,
    SUM(o.order_qty) AS total_qty,
    MAX(o.max_qty_on_hand) AS warehouse_max_on_hand
  FROM order_agg o
  GROUP BY o.w_warehouse_sk, o.w_warehouse_name
)
SELECT *
FROM (
  SELECT
    ws.w_warehouse_name,
    ws.num_orders,
    ws.sum_sales,
    ws.avg_order_sales,
    ws.total_qty,
    ws.warehouse_max_on_hand,
    (SELECT SUM(i2.inv_quantity_on_hand)
     FROM tpcds.inventory i2
     WHERE i2.inv_warehouse_sk = ws.w_warehouse_sk) AS total_inventory_qty
  FROM warehouse_summary ws
  WHERE ws.sum_sales > 5000
    AND ws.total_qty > 100
    AND ws.warehouse_max_on_hand > 200
    AND ws.num_orders >= 5
    AND ws.avg_order_sales BETWEEN 1000 AND 20000
    AND ws.w_warehouse_name IS NOT NULL

  UNION DISTINCT

  SELECT
    ws2.w_warehouse_name,
    ws2.num_orders,
    ws2.sum_sales,
    ws2.avg_order_sales,
    ws2.total_qty,
    ws2.warehouse_max_on_hand,
    (SELECT SUM(i3.inv_quantity_on_hand)
     FROM tpcds.inventory i3
     WHERE i3.inv_warehouse_sk = ws2.w_warehouse_sk) AS total_inventory_qty
  FROM warehouse_summary ws2
  WHERE ws2.sum_sales <= 5000
    AND ws2.total_qty <= 100
    AND ws2.warehouse_max_on_hand <= 200
    AND ws2.num_orders < 5
    AND ws2.avg_order_sales < 1000
    AND ws2.w_warehouse_name IS NOT NULL
) final_result
ORDER BY final_result.sum_sales DESC
LIMIT 100
