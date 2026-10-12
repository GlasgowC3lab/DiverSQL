WITH max_price AS (
   SELECT MAX(cs_ext_sales_price) AS max_price
   FROM tpcds.catalog_sales
   WHERE cs_sold_date_sk = 2451100
)
SELECT
   i.i_category,
   w.w_state,
   td.t_meal_time,
   COUNT(DISTINCT cs.cs_order_number)                     AS order_count,
   SUM(cs.cs_ext_sales_price)                           AS total_sales,
   AVG(cs.cs_ext_discount_amt)                          AS avg_discount,
   MIN(cs.cs_sold_date_sk)                              AS earliest_sold_date,
   MAX(cs.cs_sold_date_sk)                              AS latest_sold_date
FROM tpcds.catalog_sales cs
JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_time_sk = td.t_time_sk
JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_time_sk = td.t_time_sk
JOIN tpcds.web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
WHERE
   td.t_meal_time = 'lunch'
   AND i.i_category = 'Sports'
   AND w.w_state = 'CA'
   AND c.c_birth_country = 'United States'
   AND cs.cs_ext_sales_price > (SELECT max_price FROM max_price)
GROUP BY i.i_category, w.w_state, td.t_meal_time
ORDER BY total_sales DESC
LIMIT 100
