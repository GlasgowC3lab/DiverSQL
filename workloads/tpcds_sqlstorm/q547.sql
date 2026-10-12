WITH unified_sales AS (
    SELECT d.d_year AS year, cs.cs_item_sk AS item_sk, cs.cs_net_profit AS net_profit, 'Catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    UNION ALL
    SELECT d.d_year, ss.ss_item_sk, ss.ss_net_profit, 'Store'
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
    UNION ALL
    SELECT d.d_year, ws.ws_item_sk, ws.ws_net_profit, 'Web'
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
),
aggregated AS (
    SELECT year, item_sk, channel, SUM(net_profit) AS total_net_profit
    FROM unified_sales
    GROUP BY year, item_sk, channel
),
ranked AS (
    SELECT year, item_sk, channel, total_net_profit,
           ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_net_profit DESC) AS rn
    FROM aggregated
)
SELECT r.year,
       i.i_item_id,
       i.i_product_name,
       r.channel,
       r.total_net_profit
FROM ranked r
JOIN item i ON r.item_sk = i.i_item_sk
WHERE r.rn <= 10
ORDER BY r.year, r.total_net_profit DESC
