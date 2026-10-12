WITH
date_filtered AS (
 SELECT d_date_sk, d_year, d_month_seq
 FROM date_dim
 WHERE d_year BETWEEN 1998 AND 1999
),
cat_sales AS (
 SELECT d.d_year, d.d_month_seq, i.i_brand AS brand,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        SUM(cs.cs_net_profit) AS profit,
        SUM(cs.cs_quantity) AS quantity
 FROM catalog_sales cs
 JOIN date_filtered d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_brand
),
cat_returns AS (
 SELECT d.d_year, d.d_month_seq, i.i_brand AS brand,
        SUM(cr.cr_return_quantity) AS return_quantity,
        SUM(cr.cr_return_amt_inc_tax) AS return_amount,
        SUM(cr.cr_net_loss) AS net_loss
 FROM catalog_returns cr
 JOIN date_filtered d ON cr.cr_returned_date_sk = d.d_date_sk
 JOIN item i ON cr.cr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_brand
),
cat_net AS (
 SELECT s.d_year, s.d_month_seq, s.brand,
        s.sales_amount - COALESCE(r.return_amount, 0) AS net_sales_amount,
        s.profit - COALESCE(r.net_loss, 0) AS net_profit,
        s.quantity - COALESCE(r.return_quantity, 0) AS net_quantity
 FROM cat_sales s
 LEFT JOIN cat_returns r
   ON s.d_year = r.d_year AND s.d_month_seq = r.d_month_seq AND s.brand = r.brand
),
store_sales AS (
 SELECT d.d_year, d.d_month_seq, i.i_brand AS brand,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS profit,
        SUM(ss.ss_quantity) AS quantity
 FROM store_sales ss
 JOIN date_filtered d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_brand
),
store_returns AS (
 SELECT d.d_year, d.d_month_seq, i.i_brand AS brand,
        SUM(sr.sr_return_quantity) AS return_quantity,
        SUM(sr.sr_return_amt_inc_tax) AS return_amount,
        SUM(sr.sr_net_loss) AS net_loss
 FROM store_returns sr
 JOIN date_filtered d ON sr.sr_returned_date_sk = d.d_date_sk
 JOIN item i ON sr.sr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_brand
),
store_net AS (
 SELECT s.d_year, s.d_month_seq, s.brand,
        s.sales_amount - COALESCE(r.return_amount, 0) AS net_sales_amount,
        s.profit - COALESCE(r.net_loss, 0) AS net_profit,
        s.quantity - COALESCE(r.return_quantity, 0) AS net_quantity
 FROM store_sales s
 LEFT JOIN store_returns r
   ON s.d_year = r.d_year AND s.d_month_seq = r.d_month_seq AND s.brand = r.brand
),
web_sales AS (
 SELECT d.d_year, d.d_month_seq, i.i_brand AS brand,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        SUM(ws.ws_net_profit) AS profit,
        SUM(ws.ws_quantity) AS quantity
 FROM web_sales ws
 JOIN date_filtered d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_brand
),
web_returns AS (
 SELECT d.d_year, d.d_month_seq, i.i_brand AS brand,
        SUM(wr.wr_return_quantity) AS return_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS return_amount,
        SUM(wr.wr_net_loss) AS net_loss
 FROM web_returns wr
 JOIN date_filtered d ON wr.wr_returned_date_sk = d.d_date_sk
 JOIN item i ON wr.wr_item_sk = i.i_item_sk
 GROUP BY d.d_year, d.d_month_seq, i.i_brand
),
web_net AS (
 SELECT s.d_year, s.d_month_seq, s.brand,
        s.sales_amount - COALESCE(r.return_amount, 0) AS net_sales_amount,
        s.profit - COALESCE(r.net_loss, 0) AS net_profit,
        s.quantity - COALESCE(r.return_quantity, 0) AS net_quantity
 FROM web_sales s
 LEFT JOIN web_returns r
   ON s.d_year = r.d_year AND s.d_month_seq = r.d_month_seq AND s.brand = r.brand
),
combined AS (
 SELECT d_year, d_month_seq, brand, net_sales_amount, net_profit, net_quantity, 'catalog' AS channel FROM cat_net
 UNION ALL
 SELECT d_year, d_month_seq, brand, net_sales_amount, net_profit, net_quantity, 'store' AS channel FROM store_net
 UNION ALL
 SELECT d_year, d_month_seq, brand, net_sales_amount, net_profit, net_quantity, 'web' AS channel FROM web_net
),
ranked AS (
 SELECT d_year,
        d_month_seq,
        channel,
        brand,
        net_sales_amount,
        net_profit,
        net_quantity,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY net_sales_amount DESC) AS brand_rank
 FROM combined
)
SELECT d_year,
       d_month_seq,
       channel,
       brand,
       net_sales_amount,
       net_profit,
       net_quantity,
       brand_rank
FROM ranked
WHERE brand_rank <= 10
ORDER BY d_year, d_month_seq, channel, brand_rank
