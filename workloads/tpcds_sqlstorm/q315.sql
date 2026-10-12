SELECT d_year,
       i_category,
       SUM(net_profit) AS total_net_profit,
       SUM(quantity) AS total_quantity
FROM (
    SELECT d.d_year, i.i_category, cs.cs_net_profit AS net_profit, cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 1999

    UNION ALL

    SELECT d.d_year, i.i_category, ss.ss_net_profit AS net_profit, ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 1999

    UNION ALL

    SELECT d.d_year, i.i_category, ws.ws_net_profit AS net_profit, ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 1999
) t
GROUP BY d_year, i_category
ORDER BY total_net_profit DESC
LIMIT 10
