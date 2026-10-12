SELECT
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_id,
    s.s_city,
    cc.cc_name,
    cc.cc_city,
    cp.cp_type,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    CASE WHEN SUM(cr.cr_return_amount) > 0 THEN SUM(cr.cr_net_loss) / SUM(cr.cr_return_amount) END AS loss_ratio,
    d_cc_closed.d_date AS cc_closed_date,
    d_cc_open.d_date   AS cc_open_date,
    d_cp_start.d_date  AS cp_start_date,
    d_cp_end.d_date    AS cp_end_date
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_id,
    s.s_city,
    cc.cc_name,
    cc.cc_city,
    cp.cp_type,
    d_cc_closed.d_date,
    d_cc_open.d_date,
    d_cp_start.d_date,
    d_cp_end.d_date
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
