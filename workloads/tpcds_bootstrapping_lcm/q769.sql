WITH aggregated_sales AS (
  SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    d_closed.d_year AS closed_year,
    d_closed.d_month_seq AS closed_month_seq,
    d_open.d_year AS open_year,
    s.s_store_id AS s_store_id,
    s.s_store_name AS s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_floor_space AS s_floor_space,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month_seq,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    AVG(ws.ws_quantity) AS avg_quantity
  FROM call_center cc
  JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
  JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
  JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
  JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_closed.d_date_sk
  JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
  WHERE cc.cc_state = 'CA'
    AND s.s_state = 'CA'
    AND d_closed.d_year = 2022
  GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    d_closed.d_year,
    d_closed.d_month_seq,
    d_open.d_year,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_floor_space,
    d_ship.d_year,
    d_ship.d_month_seq
)
SELECT
  cc_call_center_id,
  cc_name,
  cc_city,
  cc_state,
  closed_year,
  closed_month_seq,
  open_year,
  s_store_id,
  s_store_name,
  store_city,
  store_state,
  s_floor_space,
  ship_year,
  ship_month_seq,
  total_sales,
  total_profit,
  order_cnt,
  avg_quantity,
  ROW_NUMBER() OVER (PARTITION BY cc_call_center_id ORDER BY total_sales DESC) AS sales_rank
FROM aggregated_sales
ORDER BY total_sales DESC
LIMIT 100
