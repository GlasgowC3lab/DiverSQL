SELECT
    cc.cc_division_name,
    s.s_division_name,
    d_cr.d_year AS return_year,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_tickets,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(cr.cr_return_amt_inc_tax) AS catalog_return_amount_inc_tax,
    SUM(sr.sr_return_amt_inc_tax) AS store_return_amount_inc_tax,
    AVG(cc.cc_tax_percentage) AS avg_call_center_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) AS total_net_loss,
    (SUM(cr.cr_return_amt_inc_tax) + SUM(sr.sr_return_amt_inc_tax)) AS total_return_amount_inc_tax,
    CASE 
        WHEN SUM(cr.cr_net_loss) = 0 THEN NULL
        ELSE SUM(sr.sr_net_loss) / SUM(cr.cr_net_loss)
    END AS store_to_catalog_net_loss_ratio
FROM call_center cc
JOIN catalog_returns cr
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_cr.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_cr.d_year BETWEEN 2000 AND 2020
GROUP BY
    cc.cc_division_name,
    s.s_division_name,
    d_cr.d_year
HAVING (SUM(cr.cr_net_loss) + SUM(sr.sr_net_loss)) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
