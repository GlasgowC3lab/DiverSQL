WITH store_agg AS (
  SELECT
    i.i_brand,
    d.d_year,
    d.d_quarter_seq,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ss.ss_quantity) AS store_quantity,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_current_year = 'Y'
    AND d.d_quarter_seq = 2
    AND t.t_hour BETWEEN 8 AND 12
  GROUP BY i.i_brand, d.d_year, d.d_quarter_seq
),
web_agg AS (
  SELECT
    i.i_brand,
    d.d_year,
    d.d_quarter_seq,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(ws.ws_quantity) AS web_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_current_year = 'Y'
    AND d.d_quarter_seq = 2
    AND t.t_hour BETWEEN 8 AND 12
    AND sm.sm_type = 'Air'
  GROUP BY i.i_brand, d.d_year, d.d_quarter_seq
)
SELECT
  COALESCE(sa.i_brand, wa.i_brand) AS brand,
  COALESCE(sa.d_year, wa.d_year) AS year,
  COALESCE(sa.d_quarter_seq, wa.d_quarter_seq) AS quarter,
  sa.store_net_profit,
  wa.web_net_profit,
  (wa.web_net_profit - sa.store_net_profit) AS profit_diff,
  CASE
    WHEN sa.store_net_profit = 0 THEN NULL
    ELSE (wa.web_net_profit / sa.store_net_profit) * 100
  END AS web_to_store_profit_pct
FROM store_agg sa
FULL OUTER JOIN web_agg wa
  ON sa.i_brand = wa.i_brand
  AND sa.d_year = wa.d_year
  AND sa.d_quarter_seq = wa.d_quarter_seq
ORDER BY profit_diff DESC
LIMIT 20
