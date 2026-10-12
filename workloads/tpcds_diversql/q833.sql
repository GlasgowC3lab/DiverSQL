WITH ws_agg AS (
    SELECT
        ws_warehouse_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit,
        COUNT(*) AS order_cnt,
        MIN(ws_ext_ship_cost) AS min_ship_cost,
        MAX(ws_ext_ship_cost) AS max_ship_cost
    FROM web_sales
    WHERE ws_ext_wholesale_cost > 2000.00
      AND ws_ext_ship_cost BETWEEN 300.00 AND 900.00
      AND ws_net_paid_inc_ship_tax < 5000.00
      AND ws_quantity >= 1
    GROUP BY ws_warehouse_sk
    HAVING SUM(ws_ext_sales_price) > 10000.00
),
warehouse_filtered AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        w_city,
        w_gmt_offset
    FROM warehouse
    WHERE w_gmt_offset = -5.00
      AND w_city IN ('Seattle', 'San Francisco', 'New York')
      AND w_street_type = 'Ave'
      AND w_suite_number = 'Suite 480'
),
scalar_avg_sales AS (
    SELECT AVG(total_sales) AS avg_total_sales FROM ws_agg
),
intersect_keys AS (
    SELECT ws_warehouse_sk AS w_warehouse_sk FROM ws_agg
    INTERSECT
    SELECT w_warehouse_sk FROM warehouse_filtered
),
full_joined AS (
    SELECT
        COALESCE(ws.ws_warehouse_sk, wf.w_warehouse_sk) AS w_warehouse_sk,
        ws.total_sales,
        ws.avg_profit,
        ws.order_cnt,
        wf.w_warehouse_name,
        wf.w_city,
        wf.w_gmt_offset
    FROM ws_agg ws
    FULL OUTER JOIN warehouse_filtered wf
        ON ws.ws_warehouse_sk = wf.w_warehouse_sk
    WHERE COALESCE(ws.ws_warehouse_sk, wf.w_warehouse_sk) IN (SELECT w_warehouse_sk FROM intersect_keys)
),
combined_union AS (
    SELECT * FROM full_joined WHERE total_sales IS NOT NULL
    UNION
    SELECT * FROM full_joined WHERE avg_profit IS NOT NULL
)
SELECT
    cu.w_warehouse_sk,
    cu.w_warehouse_name,
    cu.w_city,
    cu.w_gmt_offset,
    cu.total_sales,
    cu.avg_profit,
    cu.order_cnt
FROM combined_union cu
WHERE cu.total_sales > (SELECT avg_total_sales FROM scalar_avg_sales)
ORDER BY cu.total_sales DESC
LIMIT 100
