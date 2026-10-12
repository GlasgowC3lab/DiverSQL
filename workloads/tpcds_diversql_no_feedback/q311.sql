SELECT
  ws.ws_order_number,
  ws.ws_sold_date_sk,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  COUNT(wr.wr_return_quantity) AS return_cnt,
  SUM(wr.wr_refunded_cash) AS total_refunded
FROM tpcds.web_sales ws
JOIN tpcds.web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
WHERE ws.ws_net_profit > 0
  AND wr.wr_refunded_cash < 200
GROUP BY ws.ws_order_number, ws.ws_sold_date_sk
ORDER BY total_sales DESC
LIMIT 10
