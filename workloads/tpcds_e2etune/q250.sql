WITH agg AS (
  SELECT
    t.t_hour,
    t.t_shift,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    SUM(i.inv_quantity_on_hand) - SUM(cr.cr_return_quantity) AS inventory_minus_returns
  FROM catalog_returns cr
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  LEFT JOIN inventory i
    ON i.inv_item_sk = cr.cr_item_sk
   AND i.inv_warehouse_sk = cr.cr_warehouse_sk
   AND i.inv_date_sk = cr.cr_returned_date_sk
  WHERE cr.cr_call_center_sk IN (19, 40, 38)
    AND cr.cr_reason_sk NOT IN (9, 65)
    AND cr.cr_return_tax BETWEEN 5 AND 20
  GROUP BY t.t_hour, t.t_shift
)
SELECT
  t_hour,
  t_shift,
  return_cnt,
  total_return_amount,
  total_refunded_cash,
  avg_return_tax,
  total_net_loss,
  total_inventory_on_hand,
  inventory_minus_returns,
  RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 20
