WITH store_not_in_web AS (
   SELECT ss_item_sk AS item_sk FROM store_sales
   EXCEPT
   SELECT ws_item_sk FROM web_sales
)
SELECT
   d.d_year,
   i.i_category,
   SUM(CASE WHEN ss.ss_quantity IS NOT NULL THEN ss.ss_ext_sales_price ELSE 0 END) AS store_sales_amount,
   SUM(CASE WHEN ws.ws_quantity IS NOT NULL THEN ws.ws_ext_sales_price ELSE 0 END) AS web_sales_amount,
   SUM(CASE WHEN sr.sr_return_quantity IS NOT NULL THEN -sr.sr_return_amt ELSE 0 END) AS store_return_amount,
   SUM(CASE WHEN cr.cr_return_quantity IS NOT NULL THEN -cr.cr_return_amount ELSE 0 END) AS catalog_return_amount,
   CASE
      WHEN SUM(ss.ss_ext_sales_price) > 10000 THEN 'HIGH'
      ELSE 'LOW'
   END AS sales_volume_category,
   COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt,
   COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
   COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
   COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
   COUNT(DISTINCT snw.item_sk) AS sold_not_in_web_items
FROM date_dim d
LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
LEFT JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                      AND sr.sr_item_sk = i.i_item_sk
FULL OUTER JOIN catalog_returns cr
   ON cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_item_sk = i.i_item_sk
LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                     AND ws.ws_item_sk = i.i_item_sk
LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
LEFT JOIN store_not_in_web snw ON snw.item_sk = i.i_item_sk
GROUP BY ROLLUP (d.d_year, i.i_category)
ORDER BY d.d_year NULLS LAST, i.i_category NULLS LAST, store_sales_amount DESC
