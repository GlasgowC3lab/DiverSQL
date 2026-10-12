WITH
    catalog_ret AS (
        SELECT
            cr.cr_returned_date_sk AS return_date_sk,
            cr.cr_return_amount AS return_amount,
            r.r_reason_desc AS reason_desc,
            w.w_warehouse_name AS warehouse_name
        FROM catalog_returns cr
        JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cr.cr_return_amount > 50
    ),
    web_ret AS (
        SELECT
            wr.wr_returned_date_sk AS return_date_sk,
            wr.wr_return_amt AS return_amount,
            r.r_reason_desc AS reason_desc,
            w.w_warehouse_name AS warehouse_name
        FROM web_returns wr
        JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE wr.wr_return_amt > 50
    )
SELECT
    return_date_sk,
    return_amount,
    reason_desc,
    warehouse_name,
    SUM(return_amount) OVER (
        PARTITION BY warehouse_name
        ORDER BY return_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM (
    SELECT return_date_sk, return_amount, reason_desc, warehouse_name FROM catalog_ret
    UNION ALL
    SELECT return_date_sk, return_amount, reason_desc, warehouse_name FROM web_ret
) AS combined
ORDER BY return_date_sk, return_amount DESC
LIMIT 100
