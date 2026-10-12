WITH sales AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_call_center_sk AS location_sk,
         'catalog' AS channel,
         cs.cs_quantity AS quantity,
         cs.cs_ext_sales_price AS ext_sales_price,
         cs.cs_net_profit AS net_profit
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk,
         ss.ss_item_sk,
         ss.ss_store_sk,
         'store',
         ss.ss_quantity,
         ss.ss_ext_sales_price,
         ss.ss_net_profit
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk,
         ws.ws_item_sk,
         ws.ws_web_site_sk,
         'web',
         ws.ws_quantity,
         ws.ws_ext_sales_price,
         ws.ws_net_profit
  FROM web_sales ws
),
returns AS (
  SELECT cr.cr_returned_date_sk AS date_sk,
         cr.cr_item_sk AS item_sk,
         cr.cr_call_center_sk AS location_sk,
         'catalog' AS channel,
         -cr.cr_return_quantity AS quantity,
         -cr.cr_return_amount AS ext_sales_price,
         -cr.cr_net_loss AS net_profit
  FROM catalog_returns cr
  UNION ALL
  SELECT sr.sr_returned_date_sk,
         sr.sr_item_sk,
         sr.sr_store_sk,
         'store',
         -sr.sr_return_quantity,
         -sr.sr_return_amt,
         -sr.sr_net_loss
  FROM store_returns sr
  UNION ALL
  SELECT wr.wr_returned_date_sk,
         wr.wr_item_sk,
         ws.ws_web_site_sk,
         'web',
         -wr.wr_return_quantity,
         -wr.wr_return_amt,
         -wr.wr_net_loss
  FROM web_returns wr
  LEFT JOIN web_sales ws
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
),
combined AS (
  SELECT * FROM sales
  UNION ALL
  SELECT * FROM returns
),
date_agg AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    c.channel,
    i.i_category,
    i.i_class,
    i.i_brand,
    CASE 
      WHEN c.channel = 'store' THEN st.s_store_name
      WHEN c.channel = 'catalog' THEN cc.cc_name
      WHEN c.channel = 'web' THEN ws_site.web_name
    END AS location_name,
    SUM(c.ext_sales_price) AS total_sales,
    SUM(c.net_profit) AS total_profit,
    SUM(c.quantity) AS total_qty
  FROM combined c
  JOIN date_dim d ON c.date_sk = d.d_date_sk
  LEFT JOIN item i ON c.item_sk = i.i_item_sk
  LEFT JOIN store st ON c.channel = 'store' AND c.location_sk = st.s_store_sk
  LEFT JOIN call_center cc ON c.channel = 'catalog' AND c.location_sk = cc.cc_call_center_sk
  LEFT JOIN web_site ws_site ON c.channel = 'web' AND c.location_sk = ws_site.web_site_sk
  GROUP BY d.d_year,
           d.d_month_seq,
           c.channel,
           i.i_category,
           i.i_class,
           i.i_brand,
           CASE 
             WHEN c.channel = 'store' THEN st.s_store_name
             WHEN c.channel = 'catalog' THEN cc.cc_name
             WHEN c.channel = 'web' THEN ws_site.web_name
           END
),
ranked AS (
  SELECT *,
         row_number() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY total_sales DESC) AS sales_rank
  FROM date_agg
)
SELECT d_year,
       d_month_seq,
       channel,
       i_category,
       i_class,
       i_brand,
       location_name,
       total_sales,
       total_profit,
       total_qty,
       sales_rank
FROM ranked
WHERE sales_rank <= 5
ORDER BY d_year, d_month_seq, channel, sales_rank
