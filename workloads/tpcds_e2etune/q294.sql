WITH sales_agg AS (
  SELECT
    sm.sm_type AS ship_mode,
    i.i_class AS item_class,
    SUM(ws.ws_quantity) AS total_qty_sold,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE t.t_hour BETWEEN 8 AND 12
    AND ws.ws_net_profit > 0
  GROUP BY sm.sm_type, i.i_class
),
returns_agg AS (
  SELECT
    sm.sm_type AS ship_mode,
    i.i_class AS item_class,
    SUM(cr.cr_return_quantity) AS total_qty_returned,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount
  FROM catalog_returns cr
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  WHERE t.t_hour BETWEEN 8 AND 12
    AND cr.cr_net_loss > 0
  GROUP BY sm.sm_type, i.i_class
)
SELECT
  s.ship_mode,
  s.item_class,
  s.total_qty_sold,
  r.total_qty_returned,
  s.total_net_profit,
  r.total_net_loss,
  (s.total_net_profit - r.total_net_loss) AS net_contribution,
  CASE WHEN s.total_qty_sold > 0 THEN r.total_qty_returned * 100.0 / s.total_qty_sold ELSE NULL END AS return_rate_pct,
  RANK() OVER (ORDER BY (s.total_net_profit - r.total_net_loss) DESC) AS rank
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.ship_mode = r.ship_mode
 AND s.item_class = r.item_class
ORDER BY net_contribution DESC
LIMIT 20
