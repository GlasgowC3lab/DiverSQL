WITH sales_raw AS (
 SELECT d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amount
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 UNION ALL
 SELECT d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN item i ON ss.ss_item_sk = i.i_item_sk
 UNION ALL
 SELECT d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
sales_agg AS (
 SELECT d_year,
        month_seq,
        i_category,
        i_class,
        i_brand,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(discount_amount) AS total_discount
 FROM sales_raw
 WHERE d_year BETWEEN 2000 AND 2002
 GROUP BY d_year, month_seq, i_category, i_class, i_brand
),
returns_raw AS (
 SELECT cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_net_loss AS net_loss
 FROM catalog_returns cr
 UNION ALL
 SELECT sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_net_loss
 FROM store_returns sr
 UNION ALL
 SELECT wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_net_loss
 FROM web_returns wr
),
returns_agg AS (
 SELECT d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        i.i_class,
        i.i_brand,
        SUM(r.net_loss) AS total_net_loss
 FROM returns_raw r
 JOIN date_dim d ON r.date_sk = d.d_date_sk
 JOIN item i ON r.item_sk = i.i_item_sk
 WHERE d.d_year BETWEEN 2000 AND 2002
 GROUP BY d.d_year, d.d_month_seq, i.i_category, i.i_class, i.i_brand
),
combined AS (
 SELECT s.d_year,
        s.month_seq,
        s.i_category,
        s.i_class,
        s.i_brand,
        s.total_net_paid,
        s.total_net_profit,
        s.total_discount,
        COALESCE(r.total_net_loss, 0) AS total_net_loss,
        (s.total_net_paid - COALESCE(r.total_net_loss, 0)) AS net_sales_after_returns
 FROM sales_agg s
 LEFT JOIN returns_agg r
   ON s.d_year = r.d_year
  AND s.month_seq = r.month_seq
  AND s.i_category = r.i_category
  AND s.i_class = r.i_class
  AND s.i_brand = r.i_brand
)
SELECT
  d_year,
  month_seq,
  i_category,
  i_class,
  i_brand,
  total_net_paid,
  total_net_profit,
  total_discount,
  total_net_loss,
  net_sales_after_returns,
  RANK() OVER (PARTITION BY d_year ORDER BY net_sales_after_returns DESC) AS category_sales_rank,
  ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_net_profit DESC) AS brand_profit_rank_within_category
FROM combined
WHERE total_net_paid > 100000
ORDER BY d_year, month_seq, total_net_paid DESC
LIMIT 100
