WITH filtered_sales AS (
    SELECT cs.cs_order_number,
           cs.cs_sold_time_sk,
           cs.cs_ext_wholesale_cost,
           cs.cs_net_profit,
           cs.cs_quantity,
           cs.cs_ext_sales_price,
           cs.cs_net_paid_inc_tax,
           cp.cp_department,
           cp.cp_catalog_page_number,
           sm.sm_contract,
           sm.sm_type
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cp.cp_department = 'Electronics'
      AND cp.cp_catalog_page_number IN (5, 6, 18)
      AND cs.cs_sold_time_sk BETWEEN 30000 AND 70000
      AND cs.cs_ext_wholesale_cost > 1000
      AND sm.sm_contract LIKE 'G%'
),
sub1 AS (
    SELECT cs_order_number
    FROM filtered_sales
    WHERE cs_net_profit > 500
),
sub2 AS (
    SELECT cs_order_number
    FROM filtered_sales
    WHERE cs_quantity >= 2
),
intersect_orders AS (
    SELECT cs_order_number FROM sub1
    INTERSECT
    SELECT cs_order_number FROM sub2
),
agg1 AS (
    SELECT cp.cp_department AS department,
           sm.sm_type AS ship_type,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           AVG(cs.cs_net_paid_inc_tax) AS avg_paid_inc_tax,
           ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
    GROUP BY cp.cp_department, sm.sm_type
),
agg2 AS (
    SELECT cp.cp_department AS department,
           sm.sm_type AS ship_type,
           COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
           MAX(cs.cs_net_profit) AS max_profit,
           DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT cs.cs_order_number) DESC) AS department_rank
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cs.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
      AND cp.cp_start_date_sk > 2450800
    GROUP BY cp.cp_department, sm.sm_type
),
final_union AS (
    SELECT a.department,
           a.ship_type,
           a.total_sales,
           a.avg_paid_inc_tax,
           a.sales_rank,
           b.order_cnt,
           b.max_profit,
           b.department_rank,
           (SELECT MAX(cs2.cs_net_paid) FROM catalog_sales cs2) AS overall_max_paid
    FROM agg1 a
    JOIN agg2 b ON a.department = b.department AND a.ship_type = b.ship_type
    UNION
    SELECT cp.cp_department AS department,
           sm.sm_type AS ship_type,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           AVG(cs.cs_net_paid_inc_tax) AS avg_paid_inc_tax,
           ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank,
           COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
           MAX(cs.cs_net_profit) AS max_profit,
           DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT cs.cs_order_number) DESC) AS department_rank,
           (SELECT MAX(cs2.cs_net_paid) FROM catalog_sales cs2) AS overall_max_paid
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cp.cp_department = 'Electronics'
      AND sm.sm_contract LIKE 'G%'
    GROUP BY cp.cp_department, sm.sm_type
)
SELECT *
FROM final_union
LIMIT 100
