SELECT
    cc.cc_market_manager AS market_manager,
    s.s_state AS store_state,
    cp.cp_type AS catalog_type,
    format_datetime(CAST(dr_return.d_date AS timestamp), 'yyyy-MM') AS return_month,
    date_diff('day', CAST(dr_cc_open.d_date AS timestamp), CAST(dr_cc_closed.d_date AS timestamp)) AS cc_operational_days,
    date_diff('day', CAST(dr_cp_start.d_date AS timestamp), CAST(dr_cp_end.d_date AS timestamp)) AS catalog_page_duration_days,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_fee) AS avg_fee,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_return_tax) AS total_return_tax,
    SUM(cr.cr_return_ship_cost) AS total_ship_cost,
    SUM(cr.cr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_catalog_pages,
    SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_return_quantity), 0) AS avg_return_per_item,
    MAX(cr.cr_return_amount) AS max_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount,
    (cc.cc_employees + s.s_number_employees) AS total_employees
FROM catalog_returns cr
JOIN date_dim dr_return
    ON cr.cr_returned_date_sk = dr_return.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim dr_cc_closed
    ON cc.cc_closed_date_sk = dr_cc_closed.d_date_sk
JOIN date_dim dr_cc_open
    ON cc.cc_open_date_sk = dr_cc_open.d_date_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim dr_cp_start
    ON cp.cp_start_date_sk = dr_cp_start.d_date_sk
JOIN date_dim dr_cp_end
    ON cp.cp_end_date_sk = dr_cp_end.d_date_sk
JOIN store s
    ON true
JOIN date_dim dr_store
    ON s.s_closed_date_sk = dr_store.d_date_sk
WHERE dr_return.d_year = 2022
GROUP BY
    cc.cc_market_manager,
    s.s_state,
    cp.cp_type,
    format_datetime(CAST(dr_return.d_date AS timestamp), 'yyyy-MM'),
    date_diff('day', CAST(dr_cc_open.d_date AS timestamp), CAST(dr_cc_closed.d_date AS timestamp)),
    date_diff('day', CAST(dr_cp_start.d_date AS timestamp), CAST(dr_cp_end.d_date AS timestamp)),
    cc.cc_employees,
    s.s_number_employees
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
