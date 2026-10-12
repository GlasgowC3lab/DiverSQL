WITH promo_state_weekly AS (
  SELECT
    ws.ws_promo_sk,
    s.s_state,
    d.d_fy_quarter_seq,
    d.d_week_seq,
    d.d_current_year,
    i.i_category,
    SUM(ws.ws_net_profit) AS profit,
    SUM(ws.ws_quantity) AS total_qty,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_ext_sales_price) AS total_sales
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
  JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY ws.ws_promo_sk, s.s_state, d.d_fy_quarter_seq, d.d_week_seq, d.d_current_year, i.i_category
),
promo_state_rank AS (
  SELECT
    ws_promo_sk,
    s_state,
    d_fy_quarter_seq,
    d_current_year,
    i_category,
    profit,
    total_qty,
    orders,
    total_sales,
    RANK() OVER (PARTITION BY s_state, d_fy_quarter_seq, d_current_year ORDER BY profit DESC) AS rank_state_quarter,
    CASE
      WHEN profit > 50000 THEN 'HIGH'
      WHEN profit > 20000 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS profit_category
  FROM promo_state_weekly
)
SELECT
  ws_promo_sk,
  s_state,
  i_category,
  d_fy_quarter_seq AS fiscal_quarter,
  d_current_year,
  profit,
  total_qty,
  orders,
  total_sales,
  profit_category,
  rank_state_quarter
FROM promo_state_rank
WHERE rank_state_quarter <= 3
ORDER BY s_state, d_current_year, d_fy_quarter_seq, rank_state_quarter
