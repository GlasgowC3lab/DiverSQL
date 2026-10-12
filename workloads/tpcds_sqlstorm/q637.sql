SELECT d.d_year AS sales_year,
       d.d_month_seq AS sales_month,
       'catalog' AS channel,
       i.i_brand AS brand,
       cc.cc_state AS state,
       cd.cd_gender AS gender,
       SUM(cs.cs_net_paid) AS total_revenue
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY d.d_year, d.d_month_seq, i.i_brand, cc.cc_state, cd.cd_gender

UNION ALL

SELECT d.d_year AS sales_year,
       d.d_month_seq AS sales_month,
       'store' AS channel,
       i.i_brand AS brand,
       s.s_state AS state,
       cd.cd_gender AS gender,
       SUM(ss.ss_net_paid) AS total_revenue
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY d.d_year, d.d_month_seq, i.i_brand, s.s_state, cd.cd_gender

UNION ALL

SELECT d.d_year AS sales_year,
       d.d_month_seq AS sales_month,
       'web' AS channel,
       i.i_brand AS brand,
       we.web_state AS state,
       cd.cd_gender AS gender,
       SUM(ws.ws_net_paid) AS total_revenue
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY d.d_year, d.d_month_seq, i.i_brand, we.web_state, cd.cd_gender

ORDER BY sales_year, sales_month, channel, brand, state, gender
