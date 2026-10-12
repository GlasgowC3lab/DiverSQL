SELECT i.i_brand,
       i.i_category,
       d.d_year,
       ch.channel,
       SUM(ch.net_profit) AS total_profit
FROM (
    SELECT cs.cs_item_sk AS item_sk,
           cs.cs_sold_date_sk AS date_sk,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    UNION ALL
    SELECT ws.ws_item_sk,
           ws.ws_sold_date_sk,
           ws.ws_net_profit,
           'web'
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
    UNION ALL
    SELECT ss.ss_item_sk,
           ss.ss_sold_date_sk,
           ss.ss_net_profit,
           'store'
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
) AS ch
JOIN item i ON ch.item_sk = i.i_item_sk
JOIN date_dim d ON ch.date_sk = d.d_date_sk
GROUP BY i.i_brand, i.i_category, d.d_year, ch.channel
ORDER BY total_profit DESC
LIMIT 20
