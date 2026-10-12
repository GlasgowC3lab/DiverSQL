WITH
 store_sales_agg AS (
   SELECT d.d_year,
          s.s_state AS region,
          i.i_category,
          SUM(ss.ss_net_paid) AS sales,
          SUM(ss.ss_net_profit) AS profit
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   WHERE d.d_year = 1998
   GROUP BY d.d_year, s.s_state, i.i_category
 ),
 store_returns_agg AS (
   SELECT d.d_year,
          s.s_state AS region,
          i.i_category,
          SUM(sr.sr_return_amt) AS return_amt,
          SUM(sr.sr_net_loss) AS return_loss
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE d.d_year = 1998
   GROUP BY d.d_year, s.s_state, i.i_category
 ),
 catalog_sales_agg AS (
   SELECT d.d_year,
          cc.cc_state AS region,
          i.i_category,
          SUM(cs.cs_net_paid) AS sales,
          SUM(cs.cs_net_profit) AS profit
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   WHERE d.d_year = 1998
   GROUP BY d.d_year, cc.cc_state, i.i_category
 ),
 catalog_returns_agg AS (
   SELECT d.d_year,
          cc.cc_state AS region,
          i.i_category,
          SUM(cr.cr_return_amount) AS return_amt,
          SUM(cr.cr_net_loss) AS return_loss
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   WHERE d.d_year = 1998
   GROUP BY d.d_year, cc.cc_state, i.i_category
 ),
 web_sales_agg AS (
   SELECT d.d_year,
          wp.wp_type AS region,
          i.i_category,
          SUM(ws.ws_net_paid) AS sales,
          SUM(ws.ws_net_profit) AS profit
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   WHERE d.d_year = 1998
   GROUP BY d.d_year, wp.wp_type, i.i_category
 ),
 web_returns_agg AS (
   SELECT d.d_year,
          wp.wp_type AS region,
          i.i_category,
          SUM(wr.wr_return_amt) AS return_amt,
          SUM(wr.wr_net_loss) AS return_loss
   FROM web_returns wr
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   JOIN item i ON wr.wr_item_sk = i.i_item_sk
   WHERE d.d_year = 1998
   GROUP BY d.d_year, wp.wp_type, i.i_category
 ),
 combined_sales AS (
   SELECT ss.d_year,
          ss.region,
          ss.i_category,
          ss.sales - COALESCE(sr.return_amt, 0) AS net_sales,
          ss.profit - COALESCE(sr.return_loss, 0) AS net_profit,
          'store' AS channel
   FROM store_sales_agg ss
   LEFT JOIN store_returns_agg sr
     ON ss.d_year = sr.d_year
    AND ss.region = sr.region
    AND ss.i_category = sr.i_category
   UNION ALL
   SELECT cs.d_year,
          cs.region,
          cs.i_category,
          cs.sales - COALESCE(cr.return_amt, 0) AS net_sales,
          cs.profit - COALESCE(cr.return_loss, 0) AS net_profit,
          'catalog' AS channel
   FROM catalog_sales_agg cs
   LEFT JOIN catalog_returns_agg cr
     ON cs.d_year = cr.d_year
    AND cs.region = cr.region
    AND cs.i_category = cr.i_category
   UNION ALL
   SELECT ws.d_year,
          ws.region,
          ws.i_category,
          ws.sales - COALESCE(wr.return_amt, 0) AS net_sales,
          ws.profit - COALESCE(wr.return_loss, 0) AS net_profit,
          'web' AS channel
   FROM web_sales_agg ws
   LEFT JOIN web_returns_agg wr
     ON ws.d_year = wr.d_year
    AND ws.region = wr.region
    AND ws.i_category = wr.i_category
 )
SELECT d_year,
       region,
       i_category,
       SUM(CASE WHEN channel = 'store' THEN net_sales END) AS store_net_sales,
       SUM(CASE WHEN channel = 'store' THEN net_profit END) AS store_net_profit,
       SUM(CASE WHEN channel = 'catalog' THEN net_sales END) AS catalog_net_sales,
       SUM(CASE WHEN channel = 'catalog' THEN net_profit END) AS catalog_net_profit,
       SUM(CASE WHEN channel = 'web' THEN net_sales END) AS web_net_sales,
       SUM(CASE WHEN channel = 'web' THEN net_profit END) AS web_net_profit
FROM combined_sales
GROUP BY d_year, region, i_category
ORDER BY d_year, region, i_category
