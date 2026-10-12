WITH unified_sales AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_net_paid,
           ws.ws_net_profit,
           'web'
    FROM web_sales ws
    UNION ALL
    SELECT cs.cs_sold_date_sk,
           cs.cs_item_sk,
           cs.cs_net_paid,
           cs.cs_net_profit,
           'catalog'
    FROM catalog_sales cs
)
SELECT d.d_year,
       i.i_category,
       us.channel,
       SUM(us.net_paid) AS total_net_paid,
       SUM(us.net_profit) AS total_net_profit,
       COUNT(*) AS sales_count
FROM unified_sales us
JOIN date_dim d ON us.date_sk = d.d_date_sk
JOIN item i ON us.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2001
GROUP BY d.d_year, i.i_category, us.channel
HAVING SUM(us.net_profit) > 0
ORDER BY d.d_year, us.channel, total_net_profit DESC
LIMIT 200
