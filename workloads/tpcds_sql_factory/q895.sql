WITH item_agg AS (
  SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_wholesale_cost,
    w.w_warehouse_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  GROUP BY i.i_item_id, i.i_product_name, i.i_wholesale_cost, w.w_warehouse_name
)
SELECT
  i_item_id,
  i_product_name,
  w_warehouse_name,
  total_return_amount,
  total_net_loss,
  avg_return_qty,
  CASE
    WHEN i_wholesale_cost < 20 THEN 'Low'
    WHEN i_wholesale_cost BETWEEN 20 AND 50 THEN 'Medium'
    ELSE 'High'
  END AS wholesale_cost_category,
  RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM item_agg
ORDER BY net_loss_rank
LIMIT 10
