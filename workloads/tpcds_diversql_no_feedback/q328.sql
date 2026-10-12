WITH refunded_air AS (
  SELECT
    sm.sm_type AS ship_mode_type,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(DISTINCT cr.cr_return_amount) AS distinct_return_amount
  FROM catalog_returns cr
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  WHERE sm.sm_code = 'AIR'
    AND r.r_reason_desc LIKE '%Damaged%'
    AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2455000
  GROUP BY sm.sm_type
),
surface_inventory AS (
  SELECT
    sm.sm_type AS ship_mode_type,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(DISTINCT cr.cr_return_amount) AS distinct_return_amount
  FROM catalog_returns cr
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
  WHERE sm.sm_code = 'SURFACE'
    AND w.w_zip = '44593'
    AND i.inv_quantity_on_hand > 100
    AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2455000
  GROUP BY sm.sm_type
)
SELECT ship_mode_type,
       distinct_orders,
       distinct_return_amount
FROM refunded_air
UNION ALL
SELECT ship_mode_type,
       distinct_orders,
       distinct_return_amount
FROM surface_inventory
ORDER BY distinct_orders DESC,
         distinct_return_amount DESC
LIMIT 100
