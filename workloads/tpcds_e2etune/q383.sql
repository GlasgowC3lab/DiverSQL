WITH catalog_agg AS (
  SELECT
    td.t_hour,
    sm.sm_ship_mode_id,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS catalog_customers,
    SUM(cr.cr_return_quantity) AS catalog_return_qty
  FROM catalog_returns cr
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  WHERE cr.cr_return_amount > 100
    AND sm.sm_type = 'AIR'
    AND cd.cd_gender = 'M'
  GROUP BY td.t_hour, sm.sm_ship_mode_id
),
web_agg AS (
  SELECT
    td.t_hour,
    sm.sm_ship_mode_id,
    SUM(ws.ws_net_profit) AS web_net_profit,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customers,
    SUM(ws.ws_quantity) AS web_quantity
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  WHERE ws.ws_sales_price > 200
    AND sm.sm_type = 'AIR'
    AND cd.cd_gender = 'M'
  GROUP BY td.t_hour, sm.sm_ship_mode_id
)
SELECT
  COALESCE(ca.t_hour, wa.t_hour) AS hour,
  COALESCE(ca.sm_ship_mode_id, wa.sm_ship_mode_id) AS ship_mode,
  ca.catalog_net_loss,
  wa.web_net_profit,
  ca.catalog_customers,
  wa.web_customers,
  ca.catalog_return_qty,
  wa.web_quantity,
  (ca.catalog_net_loss - wa.web_net_profit) AS net_loss_minus_profit
FROM catalog_agg ca
FULL OUTER JOIN web_agg wa
  ON ca.t_hour = wa.t_hour
  AND ca.sm_ship_mode_id = wa.sm_ship_mode_id
ORDER BY net_loss_minus_profit DESC
LIMIT 20
