SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    ds.d_date AS store_closed_date,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    dc_closed.d_date AS call_center_closed_date,
    dc_open.d_date AS call_center_open_date,
    cc.cc_employees,
    cc.cc_tax_percentage,
    cp.cp_catalog_page_number,
    cp.cp_type,
    cp.cp_description,
    dp_start.d_date AS catalog_start_date,
    dp_end.d_date AS catalog_end_date,
    dr.d_year AS return_year,
    dr.d_month_seq AS return_month,
    COUNT(*) AS return_count,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN date_dim dc_closed
    ON cc.cc_closed_date_sk = dc_closed.d_date_sk
JOIN date_dim dc_open
    ON cc.cc_open_date_sk = dc_open.d_date_sk
JOIN date_dim dp_start
    ON cp.cp_start_date_sk = dp_start.d_date_sk
JOIN date_dim dp_end
    ON cp.cp_end_date_sk = dp_end.d_date_sk
CROSS JOIN store s
JOIN date_dim ds
    ON s.s_closed_date_sk = ds.d_date_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    ds.d_date,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    dc_closed.d_date,
    dc_open.d_date,
    cc.cc_employees,
    cc.cc_tax_percentage,
    cp.cp_catalog_page_number,
    cp.cp_type,
    cp.cp_description,
    dp_start.d_date,
    dp_end.d_date,
    dr.d_year,
    dr.d_month_seq
ORDER BY total_return_amount DESC
LIMIT 100
