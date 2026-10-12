SELECT
    cc.cc_call_center_id,
    cc.cc_manager,
    cc.cc_city,
    cc.cc_state,
    cc.cc_tax_percentage,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    cr.cr_net_loss,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    d_ret.d_date AS return_date,
    d_cc_open.d_date AS cc_open_date,
    d_cc_closed.d_date AS cc_closed_date,
    d_store.d_date AS store_closed_date,
    DATE_DIFF('day', d_cc_open.d_date, d_ret.d_date) AS days_since_cc_open_to_return,
    DATE_DIFF('day', d_store.d_date, d_ret.d_date) AS days_between_store_closed_and_return,
    r.r_reason_desc,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    cr.cr_return_amount * (1 + cc.cc_tax_percentage / 100) AS return_amount_with_tax,
    SUM(cr.cr_return_amount) OVER (PARTITION BY cc.cc_call_center_sk ORDER BY d_ret.d_date) AS cumulative_return_amount_by_center
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
WHERE d_ret.d_year >= 2020
  AND cc.cc_country = 'United States'
  AND s.s_state = 'CA'
ORDER BY cr.cr_return_amount DESC
LIMIT 100
