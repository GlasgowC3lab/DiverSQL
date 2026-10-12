WITH catalog_part AS (
   SELECT
       i_c.i_category AS category,
       td_c.t_hour AS hour,
       SUM(cs.cs_net_paid) AS net_sales,
       SUM(cs.cs_net_profit) AS net_profit,
       'catalog' AS source
   FROM catalog_sales cs
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i_c ON cs.cs_item_sk = i_c.i_item_sk
   JOIN time_dim td_c ON cs.cs_sold_time_sk = td_c.t_time_sk
   GROUP BY i_c.i_category, td_c.t_hour
),
store_part AS (
   SELECT
       i_s.i_category AS category,
       td_s.t_hour AS hour,
       SUM(ss.ss_net_paid) AS net_sales,
       SUM(ss.ss_net_profit) AS net_profit,
       'store' AS source
   FROM store_sales ss
   JOIN item i_s ON ss.ss_item_sk = i_s.i_item_sk
   JOIN time_dim td_s ON ss.ss_sold_time_sk = td_s.t_time_sk
   JOIN inventory inv ON inv.inv_item_sk = i_s.i_item_sk
   GROUP BY i_s.i_category, td_s.t_hour
),
union_all AS (
   SELECT * FROM catalog_part
   UNION DISTINCT
   SELECT * FROM store_part
),
final_agg AS (
   SELECT
       category,
       hour,
       SUM(net_sales) AS total_sales,
       SUM(net_profit) AS total_profit
   FROM union_all
   GROUP BY category, hour
)
SELECT
   category,
   hour,
   total_sales,
   total_profit,
   ROW_NUMBER() OVER (PARTITION BY category ORDER BY total_sales DESC) AS sales_rank
FROM final_agg
ORDER BY total_sales DESC
LIMIT 100
