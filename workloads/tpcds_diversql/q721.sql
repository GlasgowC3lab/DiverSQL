WITH sampled_sales AS (
    SELECT *
    FROM tpcds.catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
missing_orders AS (
    SELECT cs_order_number
    FROM tpcds.catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM tpcds.catalog_returns
),
joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cc.cc_state,
        sm.sm_code,
        sm.sm_contract,
        w.w_city,
        w.w_warehouse_sq_ft
    FROM sampled_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
    LEFT JOIN tpcds.web_sales ws
        ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
        AND w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND sm.sm_code IN ('AIR', 'SEA')
      AND w.w_city LIKE '%Valley%'
      AND cs.cs_quantity >= 5
      AND cs.cs_net_profit > 0
),
aggregated AS (
    SELECT
        cs_warehouse_sk,
        cs_ship_mode_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(cs_quantity) AS avg_qty
    FROM joined_data
    GROUP BY cs_warehouse_sk, cs_ship_mode_sk
    HAVING SUM(cs_net_profit) > 1000
),
ranked AS (
    SELECT
        cs_warehouse_sk,
        cs_ship_mode_sk,
        total_profit,
        sales_cnt,
        avg_qty,
        RANK() OVER (PARTITION BY cs_ship_mode_sk ORDER BY total_profit DESC) AS profit_rank
    FROM aggregated
)
SELECT
    r.cs_warehouse_sk,
    w.w_warehouse_name,
    r.cs_ship_mode_sk,
    sm.sm_code,
    r.total_profit,
    r.sales_cnt,
    r.avg_qty,
    r.profit_rank,
    (SELECT COUNT(*) FROM missing_orders) AS missing_order_cnt
FROM ranked r
JOIN tpcds.warehouse w
    ON r.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.ship_mode sm
    ON r.cs_ship_mode_sk = sm.sm_ship_mode_sk
WHERE r.profit_rank <= 5
ORDER BY r.total_profit DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
