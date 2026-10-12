WITH base AS (
   SELECT
     cr.cr_returned_date_sk,
     cr.cr_returned_time_sk,
     cr.cr_item_sk,
     cr.cr_warehouse_sk,
     cr.cr_ship_mode_sk,
     cr.cr_return_quantity,
     cr.cr_return_amount,
     cr.cr_net_loss,
     t.t_hour,
     i.i_brand,
     i.i_size,
     i.i_current_price,
     w.w_state,
     sm.sm_carrier
   FROM catalog_returns cr
   JOIN time_dim t
     ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN item i
     ON cr.cr_item_sk = i.i_item_sk
   JOIN ship_mode sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w
     ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN household_demographics hd
     ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE i.i_size = 'large'
     AND sm.sm_carrier = 'UPS'
     AND w.w_state = 'CA'
),
joined AS (
   SELECT
     b.*,
     wr.wr_return_quantity,
     wr.wr_return_amt,
     wr.wr_net_loss
   FROM base b
   JOIN web_returns wr
     ON wr.wr_item_sk = b.cr_item_sk
    AND wr.wr_returned_time_sk = b.cr_returned_time_sk
   WHERE EXISTS (
       SELECT 1
       FROM item i2
       WHERE i2.i_item_sk = wr.wr_item_sk
         AND i2.i_class_id = 13
   )
),
aggregated AS (
   SELECT
     i_brand,
     w_state,
     sm_carrier,
     SUM(cr_return_amount) AS total_return_amount,
     SUM(wr_return_amt) AS total_web_return_amt,
     COUNT(*) AS total_rows
   FROM joined
   GROUP BY CUBE (i_brand, w_state, sm_carrier)
)
SELECT
  a.i_brand,
  a.w_state,
  a.sm_carrier,
  a.total_return_amount,
  a.total_web_return_amt,
  a.total_rows,
  (SELECT AVG(i_current_price)
   FROM item i3
   WHERE i3.i_brand = a.i_brand) AS avg_price_by_brand,
  v.flag
FROM aggregated a
CROSS JOIN (
   SELECT 'A' AS flag UNION ALL SELECT 'B' AS flag
) v
WHERE a.total_return_amount > 1000
  AND a.total_web_return_amt > 500
  AND a.total_rows >= 10
ORDER BY a.total_return_amount DESC
LIMIT 100
