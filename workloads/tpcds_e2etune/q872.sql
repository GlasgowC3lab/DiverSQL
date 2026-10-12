WITH cat_agg AS (
  SELECT cr_order_number AS order_number,
         SUM(cr_return_quantity) AS cat_return_qty,
         SUM(cr_return_amt_inc_tax) AS cat_return_amt_inc_tax,
         SUM(cr_net_loss) AS cat_net_loss,
         COUNT(*) AS cat_return_cnt,
         MAX(cr_return_ship_cost) AS cat_max_ship_cost,
         MIN(cr_return_ship_cost) AS cat_min_ship_cost,
         AVG(cr_return_ship_cost) AS cat_avg_ship_cost
  FROM catalog_returns
  WHERE cr_return_ship_cost > 0
    AND cr_reason_sk IN (9, 16, 17, 59, 65)
  GROUP BY cr_order_number
),
web_agg AS (
  SELECT wr_order_number AS order_number,
         SUM(wr_return_quantity) AS web_return_qty,
         SUM(wr_return_amt_inc_tax) AS web_return_amt_inc_tax,
         SUM(wr_net_loss) AS web_net_loss,
         COUNT(*) AS web_return_cnt,
         MAX(wr_return_ship_cost) AS web_max_ship_cost,
         MIN(wr_return_ship_cost) AS web_min_ship_cost,
         AVG(wr_return_ship_cost) AS web_avg_ship_cost
  FROM web_returns
  WHERE wr_return_ship_cost > 0
    AND wr_reason_sk IN (9, 16, 17, 59, 65)
  GROUP BY wr_order_number
)
SELECT
  COALESCE(ca.order_number, wa.order_number) AS order_number,
  ca.cat_return_qty,
  ca.cat_return_amt_inc_tax,
  ca.cat_net_loss,
  ca.cat_return_cnt,
  ca.cat_max_ship_cost,
  ca.cat_min_ship_cost,
  ca.cat_avg_ship_cost,
  wa.web_return_qty,
  wa.web_return_amt_inc_tax,
  wa.web_net_loss,
  wa.web_return_cnt,
  wa.web_max_ship_cost,
  wa.web_min_ship_cost,
  wa.web_avg_ship_cost,
  (COALESCE(ca.cat_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) AS total_net_loss,
  (COALESCE(ca.cat_return_qty, 0) + COALESCE(wa.web_return_qty, 0)) AS total_return_qty,
  (COALESCE(ca.cat_return_amt_inc_tax, 0) + COALESCE(wa.web_return_amt_inc_tax, 0)) AS total_return_amt_inc_tax,
  ROW_NUMBER() OVER (ORDER BY (COALESCE(ca.cat_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) DESC) AS loss_rank
FROM cat_agg ca
FULL OUTER JOIN web_agg wa
  ON ca.order_number = wa.order_number
WHERE (COALESCE(ca.cat_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
