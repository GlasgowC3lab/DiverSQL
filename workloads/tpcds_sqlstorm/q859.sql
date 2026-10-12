WITH store_sales_agg AS (
   SELECT d.d_year AS year,
          SUM(ss.ss_net_paid) AS store_sales_amount,
          SUM(ss.ss_net_profit) AS store_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   GROUP BY d.d_year
),
web_sales_agg AS (
   SELECT d.d_year AS year,
          SUM(ws.ws_net_paid) AS web_sales_amount,
          SUM(ws.ws_net_profit) AS web_profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   GROUP BY d.d_year
),
catalog_sales_agg AS (
   SELECT d.d_year AS year,
          SUM(cs.cs_net_paid) AS catalog_sales_amount,
          SUM(cs.cs_net_profit) AS catalog_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   GROUP BY d.d_year
),
store_returns_agg AS (
   SELECT d.d_year AS year,
          SUM(sr.sr_net_loss) AS store_return_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   GROUP BY d.d_year
),
web_returns_agg AS (
   SELECT d.d_year AS year,
          SUM(wr.wr_net_loss) AS web_return_loss
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   GROUP BY d.d_year
)
SELECT COALESCE(ss.year, ws.year, cs.year, sr.year, wr.year) AS year,
       COALESCE(ss.store_sales_amount, 0) AS store_sales_amount,
       COALESCE(ss.store_profit, 0) AS store_profit,
       COALESCE(ws.web_sales_amount, 0) AS web_sales_amount,
       COALESCE(ws.web_profit, 0) AS web_profit,
       COALESCE(cs.catalog_sales_amount, 0) AS catalog_sales_amount,
       COALESCE(cs.catalog_profit, 0) AS catalog_profit,
       COALESCE(sr.store_return_loss, 0) AS store_return_loss,
       COALESCE(wr.web_return_loss, 0) AS web_return_loss
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws ON ss.year = ws.year
FULL OUTER JOIN catalog_sales_agg cs ON COALESCE(ss.year, ws.year) = cs.year
FULL OUTER JOIN store_returns_agg sr ON COALESCE(ss.year, ws.year, cs.year) = sr.year
FULL OUTER JOIN web_returns_agg wr ON COALESCE(ss.year, ws.year, cs.year, sr.year) = wr.year
ORDER BY year DESC
LIMIT 100
