WITH inv_warehouses AS (
    SELECT DISTINCT inv_warehouse_sk
    FROM inventory
),
ret_warehouses AS (
    SELECT DISTINCT cr_warehouse_sk
    FROM catalog_returns
),
warehouses_no_returns AS (
    SELECT inv_warehouse_sk
    FROM inv_warehouses
    EXCEPT
    SELECT cr_warehouse_sk
    FROM ret_warehouses
),
store_sales_agg AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS rn_store
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
),
full_store_sales AS (
    SELECT
        COALESCE(ssa.ss_store_sk, s.s_store_sk) AS store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        ssa.total_net_paid,
        ssa.sales_cnt,
        ssa.rn_store
    FROM store_sales_agg ssa
    FULL OUTER JOIN store s
        ON ssa.ss_store_sk = s.s_store_sk
),
city_filter AS (
    SELECT *
    FROM full_store_sales
    WHERE regexp_like(s_city, '^A.*town$')
      AND s_store_name LIKE '%Store%'
)
SELECT DISTINCT
    CONCAT(s_store_name, ' - ', s_city) AS store_full_name,
    total_net_paid,
    sales_cnt,
    CASE
        WHEN regexp_like(s_city, '^A.*') THEN 'City_A_Prefix'
        ELSE 'Other_City'
    END AS city_category,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS overall_rank,
    (SELECT w.w_warehouse_name
     FROM warehouse w
     WHERE w.w_warehouse_sk IN (SELECT inv_warehouse_sk FROM warehouses_no_returns)
     LIMIT 1) AS sample_warehouse_without_returns
FROM city_filter
WHERE rn_store = 1
ORDER BY overall_rank
LIMIT 100
