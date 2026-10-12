WITH ss_agg AS (
   SELECT
      ss_item_sk,
      ss_sold_date_sk,
      SUM(ss_ext_sales_price) AS total_sales,
      SUM(ss_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt
   FROM store_sales
   WHERE ss_ext_sales_price > 1000
     AND ss_wholesale_cost BETWEEN 30 AND 60
   GROUP BY ss_item_sk, ss_sold_date_sk
),
inv_agg AS (
   SELECT
      inv_item_sk,
      inv_date_sk,
      SUM(inv_quantity_on_hand) AS total_qty_on_hand
   FROM inventory
   WHERE inv_quantity_on_hand > 10
   GROUP BY inv_item_sk, inv_date_sk
),
date_filt AS (
   SELECT *
   FROM date_dim
   WHERE d_year = 2001
     AND d_fy_week_seq IN (14, 8)
     AND d_current_day = 'N'
)
SELECT
   d.d_date,
   cp.cp_department,
   cp.cp_type,
   ss_agg.total_sales,
   ss_agg.total_profit,
   ss_agg.sales_cnt,
   inv_agg.total_qty_on_hand,
   flags.grp
FROM date_filt d
JOIN ss_agg
   ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN inv_agg
   ON inv_agg.inv_date_sk = d.d_date_sk
JOIN catalog_page cp
   ON cp.cp_start_date_sk = d.d_date_sk
CROSS JOIN (SELECT 1 AS grp UNION ALL SELECT 2 AS grp) AS flags
WHERE cp.cp_department = 'Home'
  AND cp.cp_type = 'A'
ORDER BY d.d_date DESC, ss_agg.total_sales DESC
LIMIT 100
