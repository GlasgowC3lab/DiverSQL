SELECT
  sd.d_fy_quarter_seq AS fy_quarter,
  st.t_hour AS hour_of_day,
  COUNT(DISTINCT ws.ws_order_number) AS num_orders,
  SUM(ws.ws_net_profit) AS total_sales_profit,
  COALESCE(SUM(r.loss), 0) AS total_return_loss,
  SUM(ws.ws_net_profit) - COALESCE(SUM(r.loss), 0) AS net_profit_adj,
  SUM(ws.ws_quantity) AS total_quantity_sold,
  COALESCE(SUM(r.ret_qty), 0) AS total_quantity_returned,
  AVG(ws.ws_net_profit - COALESCE(r.loss, 0)) AS avg_profit_per_order
FROM web_sales ws
JOIN date_dim sd
  ON ws.ws_sold_date_sk = sd.d_date_sk
JOIN time_dim st
  ON ws.ws_sold_time_sk = st.t_time_sk
LEFT JOIN (
    SELECT
      wr.wr_order_number,
      wr.wr_item_sk,
      SUM(wr.wr_net_loss) AS loss,
      SUM(wr.wr_return_quantity) AS ret_qty
    FROM web_returns wr
    GROUP BY wr.wr_order_number, wr.wr_item_sk
) r
  ON ws.ws_order_number = r.wr_order_number
  AND ws.ws_item_sk = r.wr_item_sk
WHERE sd.d_fy_year = 1903
  AND sd.d_weekend = 'N'
  AND st.t_hour BETWEEN 8 AND 12
GROUP BY sd.d_fy_quarter_seq, st.t_hour
ORDER BY net_profit_adj DESC
LIMIT 10
