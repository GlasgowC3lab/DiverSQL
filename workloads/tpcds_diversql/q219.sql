WITH store_agg AS (
   SELECT
       'Store' AS channel,
       d.d_year,
       d.d_month_seq AS month_seq,
       s.s_store_id AS location_id,
       s.s_store_name AS location_name,
       SUM(ss.ss_ext_sales_price) AS sales_amount
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE d.d_year = 2001
     AND s.s_geography_class = 'Unknown'
   GROUP BY d.d_year, d.d_month_seq, s.s_store_id, s.s_store_name
),
catalog_agg AS (
   SELECT
       'Catalog' AS channel,
       d.d_year,
       d.d_month_seq AS month_seq,
       cc.cc_call_center_id AS location_id,
       cc.cc_name AS location_name,
       SUM(cs.cs_ext_sales_price) AS sales_amount
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE d.d_year = 2001
     AND cc.cc_market_manager = 'John Doe'
   GROUP BY d.d_year, d.d_month_seq, cc.cc_call_center_id, cc.cc_name
),
combined AS (
   SELECT * FROM store_agg
   UNION ALL
   SELECT * FROM catalog_agg
),
overall_avg AS (
   SELECT AVG(sales_amount) AS avg_sales FROM combined
)
SELECT
   c.channel,
   c.d_year,
   c.month_seq,
   c.location_id,
   c.location_name,
   c.sales_amount,
   LAG(c.sales_amount) OVER (PARTITION BY c.channel ORDER BY c.month_seq) AS prev_sales,
   SUM(c.sales_amount) OVER (PARTITION BY c.channel ORDER BY c.month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales,
   CASE WHEN c.sales_amount > (SELECT avg_sales FROM overall_avg) THEN 1 ELSE 0 END AS above_avg_flag
FROM combined c
ORDER BY c.channel, c.month_seq
LIMIT 100
