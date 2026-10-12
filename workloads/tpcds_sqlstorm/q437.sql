SELECT *
FROM (
   SELECT d.d_year AS sales_year,
          'store' AS channel,
          s.s_store_name AS location,
          SUM(ss.ss_net_profit) AS total_net_profit,
          SUM(ss.ss_ext_sales_price) AS total_sales,
          COUNT(*) AS sales_cnt
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE d.d_year = 2001
   GROUP BY d.d_year, s.s_store_name

   UNION ALL

   SELECT d.d_year AS sales_year,
          'catalog' AS channel,
          cp.cp_catalog_page_id AS location,
          SUM(cs.cs_net_profit) AS total_net_profit,
          SUM(cs.cs_ext_sales_price) AS total_sales,
          COUNT(*) AS sales_cnt
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   WHERE d.d_year = 2001
   GROUP BY d.d_year, cp.cp_catalog_page_id

   UNION ALL

   SELECT d.d_year AS sales_year,
          'web' AS channel,
          wp.wp_url AS location,
          SUM(ws.ws_net_profit) AS total_net_profit,
          SUM(ws.ws_ext_sales_price) AS total_sales,
          COUNT(*) AS sales_cnt
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   WHERE d.d_year = 2001
   GROUP BY d.d_year, wp.wp_url

   UNION ALL

   SELECT d.d_year AS sales_year,
          'call_center' AS channel,
          cc.cc_name AS location,
          SUM(-cr.cr_net_loss) AS total_net_profit,
          SUM(cr.cr_return_amount) AS total_sales,
          COUNT(*) AS sales_cnt
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   WHERE d.d_year = 2001
   GROUP BY d.d_year, cc.cc_name
) t
ORDER BY sales_year, channel, total_net_profit DESC
