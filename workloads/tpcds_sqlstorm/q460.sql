WITH
date_dim_agg AS (
 SELECT d_date_sk,
        d_year,
        d_month_seq
 FROM date_dim
),
item_dim AS (
 SELECT i_item_sk,
        i_category
 FROM item
),
store_sales_agg AS (
 SELECT d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ss.ss_quantity) AS store_quantity
 FROM store_sales ss
 JOIN date_dim_agg d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item_dim i ON ss.ss_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_sales_agg AS (
 SELECT d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ws.ws_quantity) AS web_quantity
 FROM web_sales ws
 JOIN date_dim_agg d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item_dim i ON ws.ws_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_sales_agg AS (
 SELECT d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(cs.cs_quantity) AS catalog_quantity
 FROM catalog_sales cs
 JOIN date_dim_agg d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item_dim i ON cs.cs_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
store_returns_agg AS (
 SELECT d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        SUM(sr.sr_return_amt) AS store_return_amount,
        SUM(sr.sr_net_loss) AS store_return_loss,
        SUM(sr.sr_return_quantity) AS store_return_quantity
 FROM store_returns sr
 JOIN date_dim_agg d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN item_dim i ON sr.sr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_returns_agg AS (
 SELECT d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_net_loss) AS web_return_loss,
        SUM(wr.wr_return_quantity) AS web_return_quantity
 FROM web_returns wr
 JOIN date_dim_agg d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN item_dim i ON wr.wr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_returns_agg AS (
 SELECT d.d_year,
        d.d_month_seq,
        i.i_category AS category,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(cr.cr_return_quantity) AS catalog_return_quantity
 FROM catalog_returns cr
 JOIN date_dim_agg d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN item_dim i ON cr.cr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
  COALESCE(s.d_year, w.d_year, c.d_year) AS sales_year,
  COALESCE(s.d_month_seq, w.d_month_seq, c.d_month_seq) AS sales_month_seq,
  COALESCE(s.category, w.category, c.category) AS category,
  s.store_sales,
  w.web_sales,
  c.catalog_sales,
  COALESCE(s.store_sales,0) + COALESCE(w.web_sales,0) + COALESCE(c.catalog_sales,0) AS total_sales,
  s.store_profit,
  w.web_profit,
  c.catalog_profit,
  COALESCE(s.store_profit,0) + COALESCE(w.web_profit,0) + COALESCE(c.catalog_profit,0) AS total_profit,
  COALESCE(sr.store_return_amount,0) + COALESCE(wr.web_return_amount,0) + COALESCE(crr.catalog_return_amount,0) AS total_return_amount,
  COALESCE(sr.store_return_loss,0) + COALESCE(wr.web_return_loss,0) + COALESCE(crr.catalog_return_loss,0) AS total_return_loss,
  (COALESCE(s.store_profit,0) + COALESCE(w.web_profit,0) + COALESCE(c.catalog_profit,0)) -
    (COALESCE(sr.store_return_loss,0) + COALESCE(wr.web_return_loss,0) + COALESCE(crr.catalog_return_loss,0)) AS profit_after_returns,
  RANK() OVER (PARTITION BY COALESCE(s.d_year, w.d_year, c.d_year)
               ORDER BY ((COALESCE(s.store_profit,0) + COALESCE(w.web_profit,0) + COALESCE(c.catalog_profit,0)) -
                         (COALESCE(sr.store_return_loss,0) + COALESCE(wr.web_return_loss,0) + COALESCE(crr.catalog_return_loss,0))) DESC) AS profit_rank_in_year,
  AVG(((COALESCE(s.store_profit,0) + COALESCE(w.web_profit,0) + COALESCE(c.catalog_profit,0)) -
        (COALESCE(sr.store_return_loss,0) + COALESCE(wr.web_return_loss,0) + COALESCE(crr.catalog_return_loss,0))))
      OVER (PARTITION BY COALESCE(s.category, w.category, c.category)
            ORDER BY COALESCE(s.d_month_seq, w.d_month_seq, c.d_month_seq)
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_moving_avg_3months
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w
  ON s.d_year = w.d_year AND s.d_month_seq = w.d_month_seq AND s.category = w.category
FULL OUTER JOIN catalog_sales_agg c
  ON COALESCE(s.d_year, w.d_year) = c.d_year
   AND COALESCE(s.d_month_seq, w.d_month_seq) = c.d_month_seq
   AND COALESCE(s.category, w.category) = c.category
FULL OUTER JOIN store_returns_agg sr
  ON COALESCE(s.d_year, w.d_year, c.d_year) = sr.d_year
   AND COALESCE(s.d_month_seq, w.d_month_seq, c.d_month_seq) = sr.d_month_seq
   AND COALESCE(s.category, w.category, c.category) = sr.category
FULL OUTER JOIN web_returns_agg wr
  ON COALESCE(s.d_year, w.d_year, c.d_year) = wr.d_year
   AND COALESCE(s.d_month_seq, w.d_month_seq, c.d_month_seq) = wr.d_month_seq
   AND COALESCE(s.category, w.category, c.category) = wr.category
FULL OUTER JOIN catalog_returns_agg crr
  ON COALESCE(s.d_year, w.d_year, c.d_year) = crr.d_year
   AND COALESCE(s.d_month_seq, w.d_month_seq, c.d_month_seq) = crr.d_month_seq
   AND COALESCE(s.category, w.category, c.category) = crr.category
WHERE COALESCE(s.d_year, w.d_year, c.d_year) IS NOT NULL
ORDER BY sales_year, sales_month_seq, profit_rank_in_year
LIMIT 200
