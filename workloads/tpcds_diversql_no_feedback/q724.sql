/*
Goal: Calculate departmental sales performance and inventory availability for Electronics items in Q2 of 2002, filtering high‑coupon orders and ensuring no future catalog page revisions, with detailed aggregates.
*/
WITH ws_filtered AS (
    SELECT ws.*
    FROM web_sales ws
    WHERE ws.ws_coupon_amt > 1000.00
      AND ws.ws_ship_customer_sk IN (253825, 11996091)
)
SELECT
    cp.cp_department,
    d.d_year,
    d.d_month_seq,
    i.inv_warehouse_sk,
    SUM(ws.ws_net_paid)                         AS total_net_paid,
    AVG(ws.ws_ext_sales_price)                  AS avg_ext_sales_price,
    COUNT(DISTINCT ws.ws_order_number)          AS order_cnt,
    MIN(ws.ws_coupon_amt)                       AS min_coupon,
    MAX(ws.ws_coupon_amt)                       AS max_coupon,
    inv_lateral.total_qty_for_item,
    (
        SELECT AVG(ws2.ws_ext_sales_price)
        FROM web_sales ws2
        WHERE ws2.ws_sold_date_sk = d.d_date_sk
    )                                            AS avg_sales_price_by_date
FROM ws_filtered ws
JOIN date_dim d
  ON ws.ws_sold_date_sk = d.d_date_sk
JOIN catalog_page cp
  ON cp.cp_start_date_sk = d.d_date_sk
JOIN inventory i
  ON i.inv_date_sk = d.d_date_sk
LEFT JOIN LATERAL (
    SELECT SUM(i2.inv_quantity_on_hand) AS total_qty_for_item
    FROM inventory i2
    WHERE i2.inv_item_sk = i.inv_item_sk
      AND i2.inv_date_sk = i.inv_date_sk
) AS inv_lateral ON TRUE
WHERE d.d_qoy = 2
  AND d.d_year = 2002
  AND cp.cp_department = 'Electronics'
  AND i.inv_quantity_on_hand > 500
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_page_id = cp.cp_catalog_page_id
          AND cp2.cp_end_date_sk > d.d_date_sk
      )
GROUP BY
    cp.cp_department,
    d.d_year,
    d.d_month_seq,
    i.inv_warehouse_sk,
    inv_lateral.total_qty_for_item,
    d.d_date_sk
ORDER BY total_net_paid DESC
LIMIT 100
