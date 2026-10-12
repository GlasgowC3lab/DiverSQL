WITH warehouse_inventory AS (
  SELECT inv_warehouse_sk,
         SUM(inv_quantity_on_hand) AS total_inventory_qty
  FROM inventory
  GROUP BY inv_warehouse_sk
),
base AS (
  SELECT w.w_warehouse_name,
         w.w_city,
         w.w_state,
         wi.total_inventory_qty,
         SUM(cr.cr_net_loss) AS total_net_loss,
         AVG(cr.cr_return_amount) AS avg_return_amount,
         SUM(cr.cr_refunded_cash) AS total_refunded_cash,
         COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN customer_demographics cd
    ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN warehouse_inventory wi
    ON w.w_warehouse_sk = wi.inv_warehouse_sk
  WHERE cr.cr_returned_date_sk IN (2451132, 2450983)
    AND t.t_shift = 'Evening'
    AND r.r_reason_desc IN ('Damaged', 'Defective')
    AND cd.cd_gender = 'F'
    AND sm.sm_type = 'Air'
  GROUP BY w.w_warehouse_name, w.w_city, w.w_state, wi.total_inventory_qty
  HAVING SUM(cr.cr_net_loss) > 500
)
SELECT *,
       RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM base
ORDER BY total_net_loss DESC
LIMIT 10
