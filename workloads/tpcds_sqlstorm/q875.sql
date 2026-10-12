WITH sales_all AS (
    SELECT d.d_year, i.i_category, cs.cs_net_profit AS net_profit, cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year, i.i_category, ss.ss_net_profit, ss.ss_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year, i.i_category, ws.ws_net_profit, ws.ws_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
), returns_all AS (
    SELECT d.d_year, i.i_category, -cr.cr_net_loss AS net_profit, -cr.cr_return_quantity AS quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year, i.i_category, -sr.sr_net_loss, -sr.sr_return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    UNION ALL
    SELECT d.d_year, i.i_category, -wr.wr_net_loss, -wr.wr_return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
), combined AS (
    SELECT d_year,
           i_category,
           sum(net_profit) AS total_profit,
           sum(quantity) AS total_quantity
    FROM (
        SELECT * FROM sales_all
        UNION ALL
        SELECT * FROM returns_all
    ) t
    GROUP BY d_year, i_category
)
SELECT d_year,
       i_category,
       total_profit,
       total_quantity,
       rank() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM combined
WHERE d_year BETWEEN 1998 AND 2000
ORDER BY d_year, profit_rank
LIMIT 50
