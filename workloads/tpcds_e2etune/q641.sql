WITH agg AS (
  SELECT
    sm.sm_type AS ship_mode,
    t.t_shift AS shift,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price
  FROM web_sales ws
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
  WHERE c_bill.c_preferred_cust_flag = 'Y'
    AND c_bill.c_birth_year BETWEEN 1950 AND 1965
    AND ws.ws_sales_price > 100
    AND t.t_hour BETWEEN 8 AND 20
  GROUP BY sm.sm_type, t.t_shift
  HAVING COUNT(*) > 10
)
SELECT
  ship_mode,
  shift,
  orders,
  total_profit,
  avg_sales_price,
  RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY total_profit DESC
LIMIT 20
