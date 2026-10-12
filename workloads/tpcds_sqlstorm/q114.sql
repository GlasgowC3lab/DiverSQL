WITH
store_sales_agg AS (
   SELECT
     d.d_year,
     d.d_moy AS month_num,
     s.s_state AS state,
     'store' AS sales_channel,
     SUM(ss.ss_net_paid_inc_tax) AS revenue,
     SUM(ss.ss_net_profit) AS profit,
     AVG(ss.ss_ext_discount_amt) AS avg_discount,
     COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
     COUNT(*) AS orders
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   GROUP BY d.d_year, d.d_moy, s.s_state
),
catalog_sales_agg AS (
   SELECT
     d.d_year,
     d.d_moy AS month_num,
     cc.cc_state AS state,
     'catalog' AS sales_channel,
     SUM(cs.cs_net_paid_inc_tax) AS revenue,
     SUM(cs.cs_net_profit) AS profit,
     AVG(cs.cs_ext_discount_amt) AS avg_discount,
     COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
     COUNT(*) AS orders
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   GROUP BY d.d_year, d.d_moy, cc.cc_state
),
web_sales_agg AS (
   SELECT
     d.d_year,
     d.d_moy AS month_num,
     wsite.web_state AS state,
     'web' AS sales_channel,
     SUM(ws.ws_net_paid_inc_tax) AS revenue,
     SUM(ws.ws_net_profit) AS profit,
     AVG(ws.ws_ext_discount_amt) AS avg_discount,
     COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
     COUNT(*) AS orders
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
   GROUP BY d.d_year, d.d_moy, wsite.web_state
),
sales_combined AS (
   SELECT * FROM store_sales_agg
   UNION ALL
   SELECT * FROM catalog_sales_agg
   UNION ALL
   SELECT * FROM web_sales_agg
),
state_month_agg AS (
   SELECT
     d_year,
     month_num,
     state,
     SUM(CASE WHEN sales_channel = 'store' THEN revenue ELSE 0 END) AS store_revenue,
     SUM(CASE WHEN sales_channel = 'store' THEN profit ELSE 0 END) AS store_profit,
     SUM(CASE WHEN sales_channel = 'catalog' THEN revenue ELSE 0 END) AS catalog_revenue,
     SUM(CASE WHEN sales_channel = 'catalog' THEN profit ELSE 0 END) AS catalog_profit,
     SUM(CASE WHEN sales_channel = 'web' THEN revenue ELSE 0 END) AS web_revenue,
     SUM(CASE WHEN sales_channel = 'web' THEN profit ELSE 0 END) AS web_profit,
     SUM(revenue) AS total_revenue,
     SUM(profit) AS total_profit,
     SUM(distinct_customers) AS total_distinct_customers,
     SUM(orders) AS total_orders,
     AVG(avg_discount) AS avg_discount
   FROM sales_combined
   GROUP BY d_year, month_num, state
)
SELECT
   d_year,
   month_num,
   state,
   store_revenue,
   store_profit,
   CASE WHEN store_revenue = 0 THEN NULL ELSE store_profit / store_revenue END AS store_profit_margin,
   catalog_revenue,
   catalog_profit,
   CASE WHEN catalog_revenue = 0 THEN NULL ELSE catalog_profit / catalog_revenue END AS catalog_profit_margin,
   web_revenue,
   web_profit,
   CASE WHEN web_revenue = 0 THEN NULL ELSE web_profit / web_revenue END AS web_profit_margin,
   total_revenue,
   total_profit,
   CASE WHEN total_revenue = 0 THEN NULL ELSE total_profit / total_revenue END AS total_profit_margin,
   avg_discount,
   total_distinct_customers,
   total_orders,
   ROW_NUMBER() OVER (PARTITION BY d_year, month_num ORDER BY total_profit DESC) AS profit_state_rank,
   SUM(total_revenue) OVER (PARTITION BY state ORDER BY d_year, month_num ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue_state
FROM state_month_agg
ORDER BY d_year, month_num, profit_state_rank
