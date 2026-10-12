WITH store_sales_agg AS (
    SELECT d.d_year, d.d_month_seq, i.i_category,
           SUM(ss.ss_net_paid) AS store_sales,
           SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
), store_returns_agg AS (
    SELECT d.d_year, d.d_month_seq, i.i_category,
           SUM(sr.sr_net_loss) AS store_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
), catalog_sales_agg AS (
    SELECT d.d_year, d.d_month_seq, i.i_category,
           SUM(cs.cs_net_paid) AS catalog_sales,
           SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
), catalog_returns_agg AS (
    SELECT d.d_year, d.d_month_seq, i.i_category,
           SUM(cr.cr_net_loss) AS catalog_returns
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
), web_sales_agg AS (
    SELECT d.d_year, d.d_month_seq, i.i_category,
           SUM(ws.ws_net_paid) AS web_sales,
           SUM(ws.ws_net_profit) AS web_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
), web_returns_agg AS (
    SELECT d.d_year, d.d_month_seq, i.i_category,
           SUM(wr.wr_net_loss) AS web_returns
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    coalesce(ss.d_year, sr.d_year, cs.d_year, cr.d_year, ws.d_year, wr.d_year) AS sales_year,
    coalesce(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq, cr.d_month_seq, ws.d_month_seq, wr.d_month_seq) AS month_seq,
    coalesce(ss.i_category, sr.i_category, cs.i_category, cr.i_category, ws.i_category, wr.i_category) AS category,
    coalesce(ss.store_sales, 0) + coalesce(cs.catalog_sales, 0) + coalesce(ws.web_sales, 0) AS total_sales,
    coalesce(sr.store_returns, 0) + coalesce(cr.catalog_returns, 0) + coalesce(wr.web_returns, 0) AS total_returns,
    coalesce(ss.store_profit, 0) + coalesce(cs.catalog_profit, 0) + coalesce(ws.web_profit, 0) AS total_profit
FROM store_sales_agg ss
FULL OUTER JOIN store_returns_agg sr ON ss.d_year = sr.d_year AND ss.d_month_seq = sr.d_month_seq AND ss.i_category = sr.i_category
FULL OUTER JOIN catalog_sales_agg cs ON coalesce(ss.d_year, sr.d_year) = cs.d_year AND coalesce(ss.d_month_seq, sr.d_month_seq) = cs.d_month_seq AND coalesce(ss.i_category, sr.i_category) = cs.i_category
FULL OUTER JOIN catalog_returns_agg cr ON coalesce(ss.d_year, sr.d_year, cs.d_year) = cr.d_year AND coalesce(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq) = cr.d_month_seq AND coalesce(ss.i_category, sr.i_category, cs.i_category) = cr.i_category
FULL OUTER JOIN web_sales_agg ws ON coalesce(ss.d_year, sr.d_year, cs.d_year, cr.d_year) = ws.d_year AND coalesce(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq, cr.d_month_seq) = ws.d_month_seq AND coalesce(ss.i_category, sr.i_category, cs.i_category, cr.i_category) = ws.i_category
FULL OUTER JOIN web_returns_agg wr ON coalesce(ss.d_year, sr.d_year, cs.d_year, cr.d_year, ws.d_year) = wr.d_year AND coalesce(ss.d_month_seq, sr.d_month_seq, cs.d_month_seq, cr.d_month_seq, ws.d_month_seq) = wr.d_month_seq AND coalesce(ss.i_category, sr.i_category, cs.i_category, cr.i_category, ws.i_category) = wr.i_category
WHERE (coalesce(ss.store_sales,0) + coalesce(cs.catalog_sales,0) + coalesce(ws.web_sales,0) + coalesce(sr.store_returns,0) + coalesce(cr.catalog_returns,0) + coalesce(wr.web_returns,0)) > 0
ORDER BY sales_year, month_seq, category
