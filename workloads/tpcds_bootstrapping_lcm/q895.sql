SELECT
    c.cc_name AS call_center_name,
    s.s_store_name AS store_name,
    d_cr.d_year,
    d_cr.d_current_month,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_ticket_cnt,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_return_amt_inc_tax) AS total_store_return_amount_inc_tax,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
    AVG(sr.sr_return_quantity) AS avg_store_return_qty,
    CASE
        WHEN SUM(sr.sr_net_loss) > SUM(cr.cr_net_loss) THEN 'Store higher loss'
        WHEN SUM(sr.sr_net_loss) < SUM(cr.cr_net_loss) THEN 'Catalog higher loss'
        ELSE 'Equal loss'
    END AS loss_comparison,
    (SUM(sr.sr_return_amt_inc_tax) - SUM(cr.cr_return_amount)) / NULLIF(SUM(cr.cr_return_amount), 0) AS return_amount_diff_ratio
FROM
    call_center c
    JOIN date_dim d_cc_closed ON c.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open ON c.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN catalog_returns cr ON cr.cr_call_center_sk = c.cc_call_center_sk
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN store_returns sr ON TRUE
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_s_closed ON s.s_closed_date_sk = d_s_closed.d_date_sk
WHERE
    d_cr.d_year = d_sr.d_year
    AND d_cr.d_month_seq = d_sr.d_month_seq
GROUP BY
    c.cc_name,
    s.s_store_name,
    d_cr.d_year,
    d_cr.d_current_month
ORDER BY
    total_store_net_loss DESC
LIMIT 100
