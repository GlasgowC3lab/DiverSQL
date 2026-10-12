WITH
    cr_cc AS (
        SELECT
            cr.cr_return_amount,
            cr.cr_return_tax,
            cr.cr_return_quantity,
            cr.cr_returned_date_sk,
            cr.cr_call_center_sk,
            cr.cr_warehouse_sk,
            cc.cc_market_manager,
            cc.cc_state,
            w.w_warehouse_id,
            w.w_state
        FROM tpcds.catalog_returns cr
        FULL OUTER JOIN tpcds.call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN tpcds.warehouse w
            ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE
            cr.cr_return_amount > 500
            AND cr.cr_return_tax < 50
            AND cc.cc_market_manager = 'Matthew Clifton'
            AND w.w_state = 'CA'
    ),
    return_agg AS (
        SELECT
            w_warehouse_id,
            cc_market_manager,
            SUM(cr_return_amount)          AS total_return_amount,
            COUNT(*)                       AS return_cnt
        FROM cr_cc
        GROUP BY w_warehouse_id, cc_market_manager
    ),
    ws_sample AS (
        SELECT *
        FROM tpcds.web_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    sales_join AS (
        SELECT
            ws.ws_ext_sales_price,
            ws.ws_quantity,
            ws.ws_ship_mode_sk,
            w.w_warehouse_id,
            w.w_state
        FROM ws_sample ws
        JOIN tpcds.warehouse w
            ON ws.ws_warehouse_sk = w.w_warehouse_sk
        WHERE
            ws.ws_ext_sales_price > 200
            AND ws.ws_quantity >= 2
            AND ws.ws_ship_mode_sk IN (1, 2)
            AND w.w_state = 'CA'
    ),
    sales_agg AS (
        SELECT
            w_warehouse_id,
            SUM(ws_ext_sales_price) AS total_sales_amount,
            COUNT(*)                AS sales_cnt
        FROM sales_join
        GROUP BY w_warehouse_id
    ),
    union_data AS (
        SELECT
            w_warehouse_id,
            cc_market_manager,
            total_return_amount,
            NULL                       AS total_sales_amount,
            'return'                   AS src
        FROM return_agg
        UNION DISTINCT
        SELECT
            w_warehouse_id,
            NULL                       AS cc_market_manager,
            NULL                       AS total_return_amount,
            total_sales_amount,
            'sale'                     AS src
        FROM sales_agg
    ),
    final_agg AS (
        SELECT
            w_warehouse_id,
            SUM(total_return_amount) AS sum_return,
            SUM(total_sales_amount)   AS sum_sales,
            COUNT(*)                  AS rows_cnt
        FROM union_data
        GROUP BY w_warehouse_id
    )
SELECT
    w_warehouse_id,
    sum_return,
    sum_sales,
    rows_cnt,
    SUM(sum_sales) OVER (
        ORDER BY w_warehouse_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                   AS running_sales,
    LAG(sum_return) OVER (ORDER BY w_warehouse_id) AS prev_sum_return
FROM final_agg
WHERE sum_sales > 1000
ORDER BY running_sales DESC
