SELECT
    d_year,
    i_category,
    SUM(CASE WHEN src = 'store' THEN profit ELSE 0 END) AS store_profit,
    SUM(CASE WHEN src = 'web' THEN profit ELSE 0 END) AS web_profit,
    SUM(CASE WHEN src = 'catalog' THEN profit ELSE 0 END) AS catalog_profit,
    SUM(profit) AS total_profit
FROM (
    SELECT d.d_year AS d_year, i.i_category AS i_category, ss.ss_net_profit AS profit, 'store' AS src
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year AS d_year, i.i_category AS i_category, -sr.sr_net_loss AS profit, 'store' AS src
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year AS d_year, i.i_category AS i_category, ws.ws_net_profit AS profit, 'web' AS src
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year AS d_year, i.i_category AS i_category, -wr.wr_net_loss AS profit, 'web' AS src
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year AS d_year, i.i_category AS i_category, cs.cs_net_profit AS profit, 'catalog' AS src
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year AS d_year, i.i_category AS i_category, -cr.cr_net_loss AS profit, 'catalog' AS src
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
) t
GROUP BY d_year, i_category
ORDER BY total_profit DESC
LIMIT 100
