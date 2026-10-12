SELECT
    d_cr.d_year AS return_year,
    cc.cc_state,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) AS total_combined_net_loss,
    AVG(cr.cr_return_amount) AS avg_catalog_return_amount,
    AVG(sr.sr_return_amt) AS avg_store_return_amount,
    (SUM(cr.cr_return_amount) / NULLIF(SUM(sr.sr_return_amt), 0)) AS catalog_to_store_return_ratio,
    COUNT(*) FILTER (WHERE cc.cc_tax_percentage > 5.00) AS high_tax_cc_count,
    COUNT(*) FILTER (WHERE s.s_tax_percentage > 5.00) AS high_tax_store_count
FROM
    call_center cc
    JOIN catalog_returns cr ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d_cr.d_date_sk
    JOIN store s ON s.s_store_sk = sr.sr_store_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE
    d_cc_open.d_year >= 2000
    AND d_cc_closed.d_year = d_cr.d_year
GROUP BY
    d_cr.d_year,
    cc.cc_state,
    s.s_state
HAVING
    (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) > 1000
ORDER BY
    total_combined_net_loss DESC
LIMIT 100
