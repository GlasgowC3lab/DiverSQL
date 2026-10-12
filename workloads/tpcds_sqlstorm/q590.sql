WITH store_sales_agg AS (
    SELECT d.d_year,
           i.i_category,
           SUM(ss.ss_net_profit) AS sales_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
), store_returns_agg AS (
    SELECT d.d_year,
           i.i_category,
           SUM(sr.sr_net_loss) AS returns_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
), catalog_sales_agg AS (
    SELECT d.d_year,
           i.i_category,
           SUM(cs.cs_net_profit) AS sales_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
), catalog_returns_agg AS (
    SELECT d.d_year,
           i.i_category,
           SUM(cr.cr_net_loss) AS returns_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
), web_sales_agg AS (
    SELECT d.d_year,
           i.i_category,
           SUM(ws.ws_net_profit) AS sales_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
), web_returns_agg AS (
    SELECT d.d_year,
           i.i_category,
           SUM(wr.wr_net_loss) AS returns_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category
), combined AS (
    SELECT s.d_year,
           s.i_category,
           'store' AS channel,
           s.sales_profit,
           COALESCE(r.returns_loss, 0) AS returns_loss
    FROM store_sales_agg s
    LEFT JOIN store_returns_agg r
        ON s.d_year = r.d_year AND s.i_category = r.i_category
    UNION ALL
    SELECT s.d_year,
           s.i_category,
           'catalog' AS channel,
           s.sales_profit,
           COALESCE(r.returns_loss, 0) AS returns_loss
    FROM catalog_sales_agg s
    LEFT JOIN catalog_returns_agg r
        ON s.d_year = r.d_year AND s.i_category = r.i_category
    UNION ALL
    SELECT s.d_year,
           s.i_category,
           'web' AS channel,
           s.sales_profit,
           COALESCE(r.returns_loss, 0) AS returns_loss
    FROM web_sales_agg s
    LEFT JOIN web_returns_agg r
        ON s.d_year = r.d_year AND s.i_category = r.i_category
)
SELECT d_year,
       i_category,
       channel,
       sales_profit - returns_loss AS net_profit
FROM combined
ORDER BY d_year, i_category, channel
