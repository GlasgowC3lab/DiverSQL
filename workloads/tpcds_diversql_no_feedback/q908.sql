WITH base AS (
   SELECT
      d.d_year,
      i.i_category,
      wsite.web_name,
      ss.ss_ext_sales_price,
      ss.ss_ticket_number,
      i.i_current_price,
      cs.cs_order_number
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
   JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk AND cs.cs_item_sk = i.i_item_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number AND wr.wr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'Brand#23'
     AND wsite.web_country = 'United States'
     AND ss.ss_net_paid_inc_tax > 1000
     AND cs.cs_order_number NOT IN (SELECT ws_order_number FROM web_sales)
)
SELECT
   d_year,
   i_category,
   web_name,
   SUM(ss_ext_sales_price) AS total_sales,
   COUNT(*) AS order_cnt,
   AVG(i_current_price) AS avg_item_price
FROM base
GROUP BY ROLLUP (d_year, i_category, web_name)
LIMIT 100
