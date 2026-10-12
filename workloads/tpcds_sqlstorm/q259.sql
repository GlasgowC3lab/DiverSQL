WITH cs AS (
   SELECT d.d_year AS year,
          'catalog_sales' AS channel,
          i.i_category AS category,
          cs.cs_ext_sales_price AS ext_sales,
          cs.cs_net_profit AS net_profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
),
cr AS (
   SELECT d.d_year AS year,
          'catalog_returns' AS channel,
          i.i_category AS category,
          cr.cr_return_amount AS ext_sales,
          cr.cr_net_loss AS net_profit
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
),
ss AS (
   SELECT d.d_year AS year,
          'store_sales' AS channel,
          i.i_category AS category,
          ss.ss_ext_sales_price AS ext_sales,
          ss.ss_net_profit AS net_profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
),
sr AS (
   SELECT d.d_year AS year,
          'store_returns' AS channel,
          i.i_category AS category,
          sr.sr_return_amt AS ext_sales,
          sr.sr_net_loss AS net_profit
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
),
ws AS (
   SELECT d.d_year AS year,
          'web_sales' AS channel,
          i.i_category AS category,
          ws.ws_ext_sales_price AS ext_sales,
          ws.ws_net_profit AS net_profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
),
wr AS (
   SELECT d.d_year AS year,
          'web_returns' AS channel,
          i.i_category AS category,
          wr.wr_return_amt AS ext_sales,
          wr.wr_net_loss AS net_profit
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year BETWEEN 1999 AND 2002
)
SELECT
  year,
  channel,
  category,
  SUM(ext_sales) AS total_sales,
  SUM(net_profit) AS total_profit,
  COUNT(*) AS transaction_count
FROM (
  SELECT * FROM cs
  UNION ALL
  SELECT * FROM cr
  UNION ALL
  SELECT * FROM ss
  UNION ALL
  SELECT * FROM sr
  UNION ALL
  SELECT * FROM ws
  UNION ALL
  SELECT * FROM wr
) t
GROUP BY year, channel, category
ORDER BY year, channel, total_sales DESC
