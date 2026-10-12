SELECT
    cc.cc_company_name,
    cc.cc_division_name,
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    d_return.d_year,
    d_return.d_month_seq,
    COUNT(*) AS total_returns,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_fee) AS avg_fee,
    SUM(p.p_cost) AS total_promo_cost,
    MIN(d_cc_open.d_date) AS call_center_open_date,
    MAX(d_store_close.d_date) AS store_closed_date,
    MAX(d_p_end.d_date) AS promo_end_date
FROM store_returns sr
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_close
    ON s.s_closed_date_sk = d_store_close.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store_close.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN promotion p
    ON p.p_start_date_sk = d_return.d_date_sk
JOIN date_dim d_p_end
    ON p.p_end_date_sk = d_p_end.d_date_sk
WHERE d_return.d_date BETWEEN d_cc_open.d_date AND d_store_close.d_date
  AND d_return.d_date <= d_p_end.d_date
GROUP BY
    cc.cc_company_name,
    cc.cc_division_name,
    s.s_store_name,
    s.s_city,
    p.p_promo_name,
    d_return.d_year,
    d_return.d_month_seq
ORDER BY total_net_loss DESC
LIMIT 100
