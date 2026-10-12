SELECT d.d_year,
       'store' AS channel,
       s.s_state AS region,
       i.i_category,
       SUM(ss.ss_net_paid) AS net_paid,
       SUM(ss.ss_net_profit) AS net_profit,
       COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, s.s_state, i.i_category

UNION ALL

SELECT d.d_year,
       'catalog' AS channel,
       cc.cc_state AS region,
       i.i_category,
       SUM(cs.cs_net_paid) AS net_paid,
       SUM(cs.cs_net_profit) AS net_profit,
       COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, cc.cc_state, i.i_category

UNION ALL

SELECT d.d_year,
       'web' AS channel,
       wp.wp_type AS region,
       i.i_category,
       SUM(ws.ws_net_paid) AS net_paid,
       SUM(ws.ws_net_profit) AS net_profit,
       COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE d.d_year = 2001
GROUP BY d.d_year, wp.wp_type, i.i_category
ORDER BY net_paid DESC
LIMIT 100
