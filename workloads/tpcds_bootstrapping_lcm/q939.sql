SELECT
    cc.cc_division,
    s.s_state,
    p.p_promo_name,
    d_ret.d_year,
    CASE WHEN d_ret.d_month_seq <= 6 THEN 'First_Half' ELSE 'Second_Half' END AS half_year,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    AVG(cr.cr_fee) AS avg_fee,
    SUM(cr.cr_return_quantity) AS total_quantity,
    CASE WHEN SUM(cr.cr_return_amount) > 0 THEN 'Positive_Return' ELSE 'Zero_or_Negative' END AS return_amount_category,
    DATE_DIFF('day', d_promo_start.d_date, d_promo_end.d_date) AS promo_duration_days,
    DATE_DIFF('day', d_cc_open.d_date, d_cc_closed.d_date) AS cc_open_to_closed_days
FROM catalog_returns cr
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2005
  AND cc.cc_country = 'United States'
GROUP BY
    cc.cc_division,
    s.s_state,
    p.p_promo_name,
    d_ret.d_year,
    CASE WHEN d_ret.d_month_seq <= 6 THEN 'First_Half' ELSE 'Second_Half' END,
    d_promo_start.d_date,
    d_promo_end.d_date,
    d_cc_open.d_date,
    d_cc_closed.d_date
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 100
