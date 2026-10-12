WITH sales_summary AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        SUM(ws.ws_net_profit) AS amount,
        'sales' AS src_type
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_quantity > 5
      AND ws.ws_net_profit > 0
      AND w.w_warehouse_sq_ft > 20000
    GROUP BY w.w_warehouse_id, w.w_city
),
returns_summary AS (
    SELECT
        w.w_warehouse_id,
        w.w_city,
        -SUM(wr.wr_return_amt_inc_tax) AS amount,
        'returns' AS src_type
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt_inc_tax > 100
      AND r.r_reason_desc LIKE '%damaged%'
    GROUP BY w.w_warehouse_id, w.w_city
),
combined AS (
    SELECT * FROM sales_summary
    UNION ALL
    SELECT * FROM returns_summary
)
SELECT
    combined.w_warehouse_id,
    combined.w_city,
    combined.src_type,
    combined.amount,
    ROW_NUMBER() OVER (PARTITION BY combined.w_warehouse_id ORDER BY combined.amount DESC) AS rank_per_warehouse
FROM combined
ORDER BY combined.w_warehouse_id, rank_per_warehouse
