SELECT td.t_hour,
       SUM(ss.ss_net_profit) AS total_store_profit,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
       (SELECT ss2.ss_wholesale_cost
        FROM store_sales ss2
        LIMIT 1) AS sample_wholesale_cost
FROM store_sales ss
JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
                     AND wr.wr_order_number = ws.ws_order_number
WHERE td.t_hour = 7
GROUP BY td.t_hour
HAVING SUM(ss.ss_net_profit) > 87.75
