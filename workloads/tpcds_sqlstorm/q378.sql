WITH
date_filtered AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
),
store_sales_agg AS (
    SELECT d.d_year,
           SUM(ss.ss_net_profit) AS store_net_profit,
           SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN date_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
catalog_sales_agg AS (
    SELECT d.d_year,
           SUM(cs.cs_net_profit) AS catalog_net_profit,
           SUM(cs.cs_quantity) AS catalog_quantity
    FROM catalog_sales cs
    JOIN date_filtered d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
web_sales_agg AS (
    SELECT d.d_year,
           SUM(ws.ws_net_profit) AS web_net_profit,
           SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN date_filtered d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
store_returns_agg AS (
    SELECT d.d_year,
           SUM(sr.sr_net_loss) AS store_return_loss,
           SUM(sr.sr_return_quantity) AS store_return_quantity
    FROM store_returns sr
    JOIN date_filtered d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
catalog_returns_agg AS (
    SELECT d.d_year,
           SUM(cr.cr_net_loss) AS catalog_return_loss,
           SUM(cr.cr_return_quantity) AS catalog_return_quantity
    FROM catalog_returns cr
    JOIN date_filtered d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
web_returns_agg AS (
    SELECT d.d_year,
           SUM(wr.wr_net_loss) AS web_return_loss,
           SUM(wr.wr_return_quantity) AS web_return_quantity
    FROM web_returns wr
    JOIN date_filtered d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY d.d_year
)
SELECT d.year,
       COALESCE(ss.store_net_profit, 0) AS store_net_profit,
       COALESCE(cs.catalog_net_profit, 0) AS catalog_net_profit,
       COALESCE(ws.web_net_profit, 0) AS web_net_profit,
       COALESCE(sr.store_return_loss, 0) AS store_return_loss,
       COALESCE(cr.catalog_return_loss, 0) AS catalog_return_loss,
       COALESCE(wr.web_return_loss, 0) AS web_return_loss,
       COALESCE(ss.store_quantity, 0) + COALESCE(cs.catalog_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity_sold,
       COALESCE(sr.store_return_quantity, 0) + COALESCE(cr.catalog_return_quantity, 0) + COALESCE(wr.web_return_quantity, 0) AS total_quantity_returned
FROM (SELECT DISTINCT d_year AS year FROM date_filtered) d
LEFT JOIN store_sales_agg ss ON ss.d_year = d.year
LEFT JOIN catalog_sales_agg cs ON cs.d_year = d.year
LEFT JOIN web_sales_agg ws ON ws.d_year = d.year
LEFT JOIN store_returns_agg sr ON sr.d_year = d.year
LEFT JOIN catalog_returns_agg cr ON cr.d_year = d.year
LEFT JOIN web_returns_agg wr ON wr.d_year = d.year
ORDER BY d.year
