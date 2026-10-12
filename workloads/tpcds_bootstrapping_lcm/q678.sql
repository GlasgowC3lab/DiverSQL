WITH agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_market_manager,
        w.w_warehouse_name,
        w.w_city AS warehouse_city,
        s.s_store_id,
        s.s_store_name,
        s.s_city AS store_city,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_ret.d_date AS return_date,
        d_cc_closed.d_date AS call_center_closed_date,
        d_cc_open.d_date AS call_center_open_date,
        d_store.d_date AS store_closed_date,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        AVG(cr.cr_return_tax) AS avg_return_tax,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_store
        ON s.s_closed_date_sk = d_store.d_date_sk
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_name,
        cc.cc_market_manager,
        w.w_warehouse_name,
        w.w_city,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_ret.d_year,
        d_ret.d_month_seq,
        d_ret.d_date,
        d_cc_closed.d_date,
        d_cc_open.d_date,
        d_store.d_date
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank,
    cc_call_center_id,
    cc_name,
    cc_market_manager,
    w_warehouse_name,
    warehouse_city,
    s_store_id,
    s_store_name,
    store_city,
    d_year,
    d_month_seq,
    return_date,
    call_center_closed_date,
    call_center_open_date,
    store_closed_date,
    total_return_amount,
    total_return_quantity,
    avg_return_tax,
    distinct_orders
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
