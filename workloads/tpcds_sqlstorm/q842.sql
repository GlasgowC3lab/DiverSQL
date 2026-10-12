SELECT sales_year,
       sales_channel,
       SUM(net_profit) AS total_net_profit
FROM (
    SELECT d.d_year AS sales_year,
           'store' AS sales_channel,
           ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_year,
           'catalog',
           cs.cs_net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_year,
           'web',
           ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
) t
WHERE sales_year = 2002
GROUP BY sales_year, sales_channel
ORDER BY total_net_profit DESC
LIMIT 10
