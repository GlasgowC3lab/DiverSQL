SELECT
  d_cs.d_year,
  d_cs.d_month_seq,
  s.s_state,
  SUM(cs.cs_net_paid) AS total_catalog_net_paid,
  SUM(cs.cs_net_profit) AS total_catalog_net_profit,
  SUM(ws.ws_net_paid) AS total_web_net_paid,
  SUM(ws.ws_net_profit) AS total_web_net_profit,
  SUM(wr.wr_return_amt) AS total_return_amount,
  SUM(wr.wr_net_loss) AS total_return_net_loss,
  COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
  COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
  COUNT(DISTINCT wr.wr_order_number) AS return_order_cnt,
  AVG(cs.cs_quantity) AS avg_catalog_quantity,
  AVG(ws.ws_quantity) AS avg_web_quantity,
  AVG(wr.wr_return_quantity) AS avg_return_quantity
FROM catalog_sales cs
JOIN date_dim d_cs
  ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_cs.d_date_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_cs.d_date_sk
  AND wr.wr_item_sk = ws.ws_item_sk
  AND wr.wr_order_number = ws.ws_order_number
JOIN store s
  ON s.s_closed_date_sk = d_cs.d_date_sk
WHERE d_cs.d_year >= 2000
GROUP BY d_cs.d_year, d_cs.d_month_seq, s.s_state
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY d_cs.d_year, d_cs.d_month_seq, s.s_state
LIMIT 100
