SELECT
    (d_ss.d_year * 100 + d_ss.d_month_seq) AS year_month_key,
    (d_wr.d_month_seq - d_ss.d_month_seq) AS month_diff,
    s.s_division_name,
    s.s_state,
    d_close.d_year AS store_closed_year,
    SUM(ss.ss_ext_sales_price) AS store_sales_amount,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(wr.wr_net_loss) AS net_total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    AVG(ss.ss_quantity) AS avg_store_quantity,
    AVG(ws.ws_quantity) AS avg_web_quantity,
    SUM(CASE WHEN d_ship.d_month_seq = d_ss.d_month_seq THEN 1 ELSE 0 END) AS same_month_shipments,
    AVG(date_diff('day', d_ss.d_date, d_ship.d_date)) AS avg_ship_delay_days,
    AVG(date_diff('day', d_ss.d_date, d_wr.d_date)) AS avg_return_delay_days
FROM store_sales ss
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_ss
  ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_ss.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_returns wr
  ON wr.wr_item_sk = ws.ws_item_sk
 AND wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_wr
  ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN date_dim d_close
  ON s.s_closed_date_sk = d_close.d_date_sk
WHERE d_ss.d_year BETWEEN 2015 AND 2020
  AND s.s_state IN ('CA', 'NY', 'TX')
GROUP BY
    (d_ss.d_year * 100 + d_ss.d_month_seq),
    (d_wr.d_month_seq - d_ss.d_month_seq),
    s.s_division_name,
    s.s_state,
    d_close.d_year
HAVING SUM(ss.ss_ext_sales_price) > 5000
ORDER BY store_sales_amount DESC
LIMIT 100
