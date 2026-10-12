WITH store_data AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           SUM(ss.ss_net_profit) AS profit,
           COALESCE(SUM(sr.sr_net_loss), 0) AS loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, i.i_category
),
catalog_data AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           SUM(cs.cs_net_profit) AS profit,
           COALESCE(SUM(cr.cr_net_loss), 0) AS loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_item_sk = cs.cs_item_sk
     AND cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, i.i_category
),
web_data AS (
    SELECT d.d_year AS year,
           i.i_category AS category,
           SUM(ws.ws_net_profit) AS profit,
           COALESCE(SUM(wr.wr_net_loss), 0) AS loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = ws.ws_item_sk
     AND wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year, i.i_category
)
SELECT year,
       category,
       SUM(profit - loss) AS total_net_profit
FROM (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM catalog_data
    UNION ALL
    SELECT * FROM web_data
) t
GROUP BY year, category
ORDER BY year, category
