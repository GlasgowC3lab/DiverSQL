WITH combined_sales AS (
    SELECT cs.cs_order_number AS order_number,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_ticket_number AS order_number,
           ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_quantity AS quantity,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_order_number AS order_number,
           ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_quantity AS quantity,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           'web' AS channel
    FROM web_sales ws
)
SELECT d.d_year,
       c.channel,
       i.i_category,
       SUM(c.net_paid) AS total_net_paid,
       SUM(c.net_profit) AS total_net_profit,
       COUNT(DISTINCT c.order_number) AS distinct_orders,
       AVG(c.quantity) AS avg_quantity,
       SUM(c.net_profit) / NULLIF(SUM(c.net_paid), 0) AS profit_margin
FROM combined_sales c
JOIN date_dim d ON c.date_sk = d.d_date_sk
JOIN item i ON c.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1998 AND 2002
GROUP BY d.d_year, c.channel, i.i_category
HAVING SUM(c.net_profit) > 1000000
ORDER BY d.d_year, c.channel, total_net_profit DESC
