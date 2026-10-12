SELECT
    year,
    i_category,
    SUM(store_profit) AS store_net_profit,
    SUM(web_profit) AS web_net_profit,
    SUM(catalog_profit) AS catalog_net_profit,
    SUM(total_profit) AS total_net_profit
FROM (
    SELECT d.d_year AS year,
           i.i_category,
           ss.ss_net_profit AS store_profit,
           CAST(0 AS decimal(7,2)) AS web_profit,
           CAST(0 AS decimal(7,2)) AS catalog_profit,
           ss.ss_net_profit AS total_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_year AS year,
           i.i_category,
           CAST(0 AS decimal(7,2)) AS store_profit,
           ws.ws_net_profit AS web_profit,
           CAST(0 AS decimal(7,2)) AS catalog_profit,
           ws.ws_net_profit AS total_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT d.d_year AS year,
           i.i_category,
           CAST(0 AS decimal(7,2)) AS store_profit,
           CAST(0 AS decimal(7,2)) AS web_profit,
           cs.cs_net_profit AS catalog_profit,
           cs.cs_net_profit AS total_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
) t
GROUP BY year, i_category
ORDER BY year, i_category
