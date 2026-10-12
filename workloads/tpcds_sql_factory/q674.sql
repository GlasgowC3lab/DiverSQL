WITH class_state_daily AS (
  SELECT
    i.i_class,
    s.s_state,
    d_sold.d_date,
    SUM(ws.ws_net_profit) AS daily_profit
  FROM web_sales ws
  JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
  JOIN store s ON s.s_closed_date_sk = d_ship.d_date_sk
  GROUP BY i.i_class, s.s_state, d_sold.d_date
),
cumulative_profit AS (
  SELECT
    i_class,
    s_state,
    d_date,
    daily_profit,
    SUM(daily_profit) OVER (PARTITION BY i_class, s_state ORDER BY d_date
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit
  FROM class_state_daily
)
SELECT
  i_class,
  s_state,
  d_date,
  daily_profit,
  cum_profit,
  CASE
    WHEN LAG(cum_profit) OVER (PARTITION BY i_class, s_state ORDER BY d_date) IS NULL THEN 'START'
    WHEN cum_profit > LAG(cum_profit) OVER (PARTITION BY i_class, s_state ORDER BY d_date) THEN 'UP'
    WHEN cum_profit < LAG(cum_profit) OVER (PARTITION BY i_class, s_state ORDER BY d_date) THEN 'DOWN'
    ELSE 'NO_CHANGE'
  END AS trend,
  DENSE_RANK() OVER (PARTITION BY d_date ORDER BY cum_profit DESC) AS daily_class_state_rank
FROM cumulative_profit
WHERE d_date = (SELECT MAX(d_date) FROM date_dim)
ORDER BY i_class, s_state
