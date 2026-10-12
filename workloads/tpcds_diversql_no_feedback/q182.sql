WITH full_join AS (
  SELECT
    ws.ws_order_number,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    w.w_warehouse_name,
    d.d_year,
    d.d_day_name
  FROM web_sales ws
  FULL OUTER JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE (w.w_state = 'NY' OR w.w_state IS NULL)
    AND (d.d_current_month = 'Y' OR d.d_current_month IS NULL)
    AND ws.ws_ext_tax > 20
),
inner_join AS (
  SELECT
    ws.ws_order_number,
    ws.ws_ext_sales_price,
    ws.ws_net_profit,
    w.w_warehouse_name,
    d.d_year,
    d.d_day_name
  FROM web_sales ws
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE w.w_state = 'TN'
    AND d.d_day_name = 'Monday'
    AND ws.ws_ext_tax BETWEEN 10 AND 100
)
SELECT
  ws_order_number,
  ws_ext_sales_price,
  ws_net_profit,
  w_warehouse_name,
  d_year,
  d_day_name
FROM full_join
UNION ALL
SELECT
  ws_order_number,
  ws_ext_sales_price,
  ws_net_profit,
  w_warehouse_name,
  d_year,
  d_day_name
FROM inner_join
ORDER BY ws_order_number DESC
LIMIT 100
