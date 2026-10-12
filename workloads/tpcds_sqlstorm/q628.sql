WITH
 store_agg AS (
  SELECT
   d.d_date AS sale_date,
   i.i_category AS category,
   i.i_brand AS brand,
   s.s_store_name AS location_name,
   p.p_promo_name AS promo_name,
   SUM(ss.ss_ext_sales_price) AS total_sales,
   SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_returns,
   SUM(ss.ss_net_profit) AS total_profit,
   SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
   COUNT(DISTINCT ss.ss_ticket_number) AS orders,
   SUM(ss.ss_quantity) AS total_quantity
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number AND sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY ROLLUP (d.d_date, i.i_category, i.i_brand, s.s_store_name, p.p_promo_name)
 ),
 catalog_agg AS (
  SELECT
   d.d_date AS sale_date,
   i.i_category AS category,
   i.i_brand AS brand,
   cc.cc_name AS location_name,
   p.p_promo_name AS promo_name,
   SUM(cs.cs_ext_sales_price) AS total_sales,
   SUM(COALESCE(cr.cr_return_amt_inc_tax, 0)) AS total_returns,
   SUM(cs.cs_net_profit) AS total_profit,
   SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
   COUNT(DISTINCT cs.cs_order_number) AS orders,
   SUM(cs.cs_quantity) AS total_quantity
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number AND cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY ROLLUP (d.d_date, i.i_category, i.i_brand, cc.cc_name, p.p_promo_name)
 ),
 web_agg AS (
  SELECT
   d.d_date AS sale_date,
   i.i_category AS category,
   i.i_brand AS brand,
   wp.wp_url AS location_name,
   p.p_promo_name AS promo_name,
   SUM(ws.ws_ext_sales_price) AS total_sales,
   SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_returns,
   SUM(ws.ws_net_profit) AS total_profit,
   SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
   COUNT(DISTINCT ws.ws_order_number) AS orders,
   SUM(ws.ws_quantity) AS total_quantity
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number AND wr.wr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
  GROUP BY ROLLUP (d.d_date, i.i_category, i.i_brand, wp.wp_url, p.p_promo_name)
 ),
 unioned AS (
  SELECT 'store' AS channel, *
  FROM store_agg
  UNION ALL
  SELECT 'catalog' AS channel, *
  FROM catalog_agg
  UNION ALL
  SELECT 'web' AS channel, *
  FROM web_agg
 )
SELECT
  channel,
  sale_date,
  category,
  brand,
  location_name,
  promo_name,
  total_sales,
  total_returns,
  total_sales - total_returns AS net_sales,
  total_profit,
  total_return_loss,
  orders,
  total_quantity,
  ROW_NUMBER() OVER (PARTITION BY channel, sale_date ORDER BY total_profit DESC) AS profit_rank
FROM unioned
WHERE sale_date IS NOT NULL
ORDER BY channel, sale_date, profit_rank
