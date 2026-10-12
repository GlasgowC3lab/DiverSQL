SELECT d_year,
       channel,
       i_category,
       total_net_profit,
       ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_net_profit DESC) AS channel_rank
FROM (
    SELECT d.d_year,
           'store' AS channel,
           i.i_category,
           SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, i.i_category
    UNION ALL
    SELECT d.d_year,
           'catalog' AS channel,
           i.i_category,
           SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, i.i_category
    UNION ALL
    SELECT d.d_year,
           'web' AS channel,
           i.i_category,
           SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, i.i_category
) t
ORDER BY channel, total_net_profit DESC
LIMIT 100
