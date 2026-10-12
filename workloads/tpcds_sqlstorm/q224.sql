WITH sales AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_net_profit AS profit,
           'Catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_item_sk AS item_sk,
           ss.ss_net_profit AS profit,
           'Store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_item_sk AS item_sk,
           ws.ws_net_profit AS profit,
           'Web' AS channel
    FROM web_sales ws
)
SELECT d.d_year,
       i.i_category,
       s.channel,
       sum(s.profit) AS total_profit
FROM sales s
JOIN date_dim d ON s.date_sk = d.d_date_sk
JOIN item i ON s.item_sk = i.i_item_sk
WHERE d.d_year = 2000
GROUP BY d.d_year, i.i_category, s.channel
ORDER BY total_profit DESC
LIMIT 100
