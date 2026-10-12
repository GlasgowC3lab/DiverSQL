WITH sales AS (
  SELECT ws.ws_order_number,
         ws.ws_item_sk,
         ws.ws_web_page_sk,
         ws.ws_web_site_sk,
         ws.ws_sold_date_sk,
         ws.ws_ext_sales_price,
         ws.ws_net_profit,
         ws.ws_quantity,
         ws.ws_ext_discount_amt
  FROM web_sales ws
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2455000
    AND ws.ws_quantity > 0
),
returns AS (
  SELECT wr.wr_order_number,
         wr.wr_item_sk,
         wr.wr_web_page_sk,
         SUM(wr.wr_return_amt_inc_tax) AS total_return_amt,
         SUM(wr.wr_return_quantity) AS total_return_qty,
         SUM(wr.wr_net_loss) AS total_return_loss
  FROM web_returns wr
  WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2455000
    AND wr.wr_return_quantity > 0
  GROUP BY wr.wr_order_number, wr.wr_item_sk, wr.wr_web_page_sk
)
SELECT s.ws_web_site_sk AS web_site_sk,
       site.web_name,
       s.ws_web_page_sk AS web_page_sk,
       page.wp_type,
       COUNT(DISTINCT s.ws_order_number) AS num_orders,
       SUM(s.ws_ext_sales_price) AS total_sales,
       COALESCE(SUM(r.total_return_amt), 0) AS total_returns,
       SUM(s.ws_net_profit) - COALESCE(SUM(r.total_return_loss), 0) AS net_profit_adj,
       AVG(s.ws_ext_discount_amt) AS avg_discount,
       RANK() OVER (ORDER BY SUM(s.ws_net_profit) - COALESCE(SUM(r.total_return_loss), 0) DESC) AS profit_rank
FROM sales s
LEFT JOIN returns r
  ON s.ws_order_number = r.wr_order_number
  AND s.ws_item_sk = r.wr_item_sk
  AND s.ws_web_page_sk = r.wr_web_page_sk
JOIN web_page page
  ON s.ws_web_page_sk = page.wp_web_page_sk
JOIN web_site site
  ON s.ws_web_site_sk = site.web_site_sk
WHERE page.wp_type IN ('category', 'product')
GROUP BY s.ws_web_site_sk, site.web_name, s.ws_web_page_sk, page.wp_type
ORDER BY net_profit_adj DESC
LIMIT 10
