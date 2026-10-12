WITH
catalog_agg AS (
   SELECT
        d.d_year,
        cc.cc_name AS channel_name,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_sales_price) AS avg_sales_price
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   GROUP BY d.d_year, cc.cc_name
),
catalog_rank AS (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
   FROM catalog_agg
),
store_agg AS (
   SELECT
        d.d_year,
        s.s_store_name AS channel_name,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_sales_price
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
   GROUP BY d.d_year, s.s_store_name
),
store_rank AS (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
   FROM store_agg
),
web_agg AS (
   SELECT
        d.d_year,
        wp.wp_type AS channel_name,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   GROUP BY d.d_year, wp.wp_type
),
web_rank AS (
   SELECT *,
          ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
   FROM web_agg
),
combined AS (
   SELECT 'Catalog' AS sales_channel, d_year, channel_name, total_profit, total_sales,
          distinct_customers, distinct_items, total_quantity, avg_sales_price, profit_rank
   FROM catalog_rank
   UNION ALL
   SELECT 'Store' AS sales_channel, d_year, channel_name, total_profit, total_sales,
          distinct_customers, distinct_items, total_quantity, avg_sales_price, profit_rank
   FROM store_rank
   UNION ALL
   SELECT 'Web' AS sales_channel, d_year, channel_name, total_profit, total_sales,
          distinct_customers, distinct_items, total_quantity, avg_sales_price, profit_rank
   FROM web_rank
)
SELECT
  d_year,
  sales_channel,
  channel_name,
  total_profit,
  total_sales,
  CASE WHEN total_sales = 0 THEN NULL ELSE total_profit / total_sales END AS profit_margin,
  distinct_customers,
  distinct_items,
  total_quantity,
  avg_sales_price,
  CASE WHEN distinct_customers = 0 THEN NULL ELSE total_sales / distinct_customers END AS sales_per_customer,
  profit_rank,
  AVG(total_profit) OVER (PARTITION BY sales_channel ORDER BY d_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_3yr_moving_avg
FROM combined
ORDER BY d_year, sales_channel, profit_rank
