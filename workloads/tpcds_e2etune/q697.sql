SELECT
    wp.wp_type,
    c.c_preferred_cust_flag,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    (SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) AS net_profit_after_returns,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(ws.ws_quantity) AS total_quantity,
    RANK() OVER (PARTITION BY wp.wp_type ORDER BY (SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0)) DESC) AS profit_rank
FROM web_sales ws
JOIN customer c
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_item_sk = ws.ws_item_sk
WHERE ws.ws_sold_date_sk BETWEEN 2449000 AND 2450000
  AND wp.wp_image_count > 0
GROUP BY wp.wp_type, c.c_preferred_cust_flag
HAVING COUNT(DISTINCT ws.ws_order_number) >= 10
ORDER BY net_profit_after_returns DESC
LIMIT 100
