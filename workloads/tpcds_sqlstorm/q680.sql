WITH sales AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           'store' AS channel,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year AS year,
           i.i_category AS category,
           'catalog' AS channel,
           cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year AS year,
           i.i_category AS category,
           'web' AS channel,
           ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
)
SELECT year,
       category,
       channel,
       SUM(net_profit) AS total_profit
FROM sales
WHERE year = 2001
GROUP BY year, category, channel
ORDER BY total_profit DESC
LIMIT 20
