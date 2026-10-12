WITH date_filter AS (
   SELECT d_date_sk, d_year, d_quarter_seq
   FROM date_dim
   WHERE d_year BETWEEN 1999 AND 2002
),
store_sales_agg AS (
   SELECT
     ss.ss_store_sk AS store_sk,
     i.i_category AS category,
     d.d_year,
     d.d_quarter_seq,
     SUM(ss.ss_net_profit) AS profit,
     SUM(ss.ss_ext_sales_price) AS revenue,
     COUNT(DISTINCT ss.ss_ticket_number) AS orders,
     COUNT(DISTINCT CASE WHEN ss.ss_promo_sk IS NOT NULL THEN ss.ss_ticket_number END) AS promo_orders
   FROM store_sales ss
   JOIN date_filter d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   GROUP BY ss.ss_store_sk, i.i_category, d.d_year, d.d_quarter_seq
),
web_sales_agg AS (
   SELECT
     ws.ws_web_site_sk AS store_sk,
     i.i_category AS category,
     d.d_year,
     d.d_quarter_seq,
     SUM(ws.ws_net_profit) AS profit,
     SUM(ws.ws_ext_sales_price) AS revenue,
     COUNT(DISTINCT ws.ws_order_number) AS orders,
     COUNT(DISTINCT CASE WHEN ws.ws_promo_sk IS NOT NULL THEN ws.ws_order_number END) AS promo_orders
   FROM web_sales ws
   JOIN date_filter d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   GROUP BY ws.ws_web_site_sk, i.i_category, d.d_year, d.d_quarter_seq
),
catalog_sales_agg AS (
   SELECT
     cs.cs_call_center_sk AS store_sk,
     i.i_category AS category,
     d.d_year,
     d.d_quarter_seq,
     SUM(cs.cs_net_profit) AS profit,
     SUM(cs.cs_ext_sales_price) AS revenue,
     COUNT(DISTINCT cs.cs_order_number) AS orders,
     COUNT(DISTINCT CASE WHEN cs.cs_promo_sk IS NOT NULL THEN cs.cs_order_number END) AS promo_orders
   FROM catalog_sales cs
   JOIN date_filter d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   GROUP BY cs.cs_call_center_sk, i.i_category, d.d_year, d.d_quarter_seq
),
combined_sales AS (
   SELECT store_sk, category, d_year, d_quarter_seq, profit, revenue, orders, promo_orders FROM store_sales_agg
   UNION ALL
   SELECT store_sk, category, d_year, d_quarter_seq, profit, revenue, orders, promo_orders FROM web_sales_agg
   UNION ALL
   SELECT store_sk, category, d_year, d_quarter_seq, profit, revenue, orders, promo_orders FROM catalog_sales_agg
),
store_info AS (
   SELECT c.cc_call_center_sk AS store_sk, c.cc_name AS store_name, c.cc_state AS state, c.cc_city AS city
   FROM call_center c
   UNION ALL
   SELECT s.s_store_sk AS store_sk, s.s_store_name AS store_name, s.s_state AS state, s.s_city AS city
   FROM store s
   UNION ALL
   SELECT w.web_site_sk AS store_sk, w.web_name AS store_name, w.web_state AS state, w.web_city AS city
   FROM web_site w
),
final_agg AS (
   SELECT
     si.store_name,
     si.state,
     si.city,
     cs.category,
     cs.d_year,
     cs.d_quarter_seq,
     SUM(cs.profit) AS total_profit,
     SUM(cs.revenue) AS total_revenue,
     SUM(cs.orders) AS total_orders,
     SUM(cs.promo_orders) AS total_promo_orders
   FROM combined_sales cs
   JOIN store_info si ON cs.store_sk = si.store_sk
   GROUP BY si.store_name, si.state, si.city, cs.category, cs.d_year, cs.d_quarter_seq
),
ranked AS (
   SELECT
     final_agg.*,
     ROW_NUMBER() OVER (PARTITION BY d_year, d_quarter_seq ORDER BY total_profit DESC) AS profit_rank,
     total_profit / NULLIF(total_orders, 0) AS profit_per_order,
     total_revenue / NULLIF(total_orders, 0) AS revenue_per_order,
     total_promo_orders / NULLIF(total_orders, 0) AS promo_order_ratio,
     total_profit / NULLIF(total_promo_orders, 0) AS profit_per_promo_order
   FROM final_agg
)
SELECT
  d_year,
  d_quarter_seq,
  store_name,
  state,
  city,
  category,
  total_profit,
  total_revenue,
  total_orders,
  profit_per_order,
  revenue_per_order,
  total_promo_orders,
  promo_order_ratio,
  profit_per_promo_order,
  profit_rank
FROM ranked
WHERE profit_rank <= 10
ORDER BY d_year, d_quarter_seq, profit_rank
