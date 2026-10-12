WITH sales_orders AS (
       SELECT DISTINCT ws.ws_order_number AS order_number
       FROM web_sales ws
       WHERE ws.ws_ext_sales_price > 5000
   ),
   return_orders AS (
       SELECT DISTINCT cr.cr_order_number AS order_number
       FROM catalog_returns cr
       WHERE cr.cr_fee > 70
   ),
   orders_without_returns AS (
       SELECT order_number
       FROM sales_orders
       EXCEPT
       SELECT order_number
       FROM return_orders
   ),
   detailed AS (
       SELECT
           td.t_hour,
           ws.ws_order_number,
           ws.ws_ext_sales_price,
           ws.ws_net_profit,
           cr.cr_net_loss,
           cr.cr_fee
       FROM time_dim td
       JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
       JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
       JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
       JOIN web_returns wr ON wr.wr_returned_time_sk = td.t_time_sk
           AND wr.wr_item_sk = ws.ws_item_sk
           AND wr.wr_order_number = ws.ws_order_number
       WHERE td.t_hour IN (12, 14)
         AND td.t_am_pm = 'PM'
         AND cr.cr_fee > 50
         AND ws.ws_ext_list_price > 5000
         AND ws.ws_order_number NOT IN (SELECT cr_order_number FROM catalog_returns)
         AND ws.ws_order_number IN (SELECT order_number FROM orders_without_returns)
   )
SELECT
    d.t_hour,
    COUNT(DISTINCT d.ws_order_number) AS distinct_orders,
    SUM(d.ws_ext_sales_price) AS total_sales,
    SUM(d.cr_net_loss) AS total_return_loss,
    RANK() OVER (ORDER BY SUM(d.cr_net_loss) DESC) AS loss_rank,
    CASE WHEN SUM(d.ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
FROM detailed d
GROUP BY d.t_hour
HAVING SUM(d.cr_net_loss) > 100
ORDER BY loss_rank
LIMIT 100
