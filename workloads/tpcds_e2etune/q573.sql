WITH agg AS (
  SELECT
    ws.web_country,
    ws.web_state,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand
  FROM catalog_returns cr
  JOIN inventory inv
    ON cr.cr_item_sk = inv.inv_item_sk
   AND cr.cr_warehouse_sk = inv.inv_warehouse_sk
   AND cr.cr_returned_date_sk = inv.inv_date_sk
  JOIN web_site ws
    ON cr.cr_returned_date_sk = ws.web_open_date_sk
  WHERE cr.cr_return_ship_cost > 0
    AND cr.cr_return_tax BETWEEN 5 AND 20
    AND ws.web_gmt_offset BETWEEN -5 AND 5
  GROUP BY ws.web_country, ws.web_state
  HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
  web_country,
  web_state,
  total_return_amount,
  total_refunded_cash,
  total_net_loss,
  avg_return_quantity,
  total_inventory_on_hand,
  RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 20
