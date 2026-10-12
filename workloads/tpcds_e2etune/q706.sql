SELECT
  w.w_state AS warehouse_state,
  p.p_promo_name AS promotion_name,
  ws.ws_sold_date_sk AS sold_date_key,
  SUM(ws.ws_net_profit) AS total_sales_profit,
  SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
  SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0)) AS net_profit_after_returns,
  SUM(ws.ws_quantity) AS total_quantity_sold,
  SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
  AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
  COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
LEFT JOIN web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
  AND ws.ws_item_sk = wr.wr_item_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
  AND p.p_discount_active = 'Y'
  AND w.w_state IN ('CA', 'TX', 'NY')
GROUP BY
  w.w_state,
  p.p_promo_name,
  ws.ws_sold_date_sk
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY net_profit_after_returns DESC
LIMIT 100
