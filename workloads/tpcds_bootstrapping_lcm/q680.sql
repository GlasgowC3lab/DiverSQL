SELECT
    cc.cc_call_center_id,
    cc.cc_company_name,
    d_cc_open.d_year AS cc_open_year,
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    t.t_hour,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    AVG(sr.sr_fee) AS avg_fee,
    MAX(sr.sr_return_tax) AS max_return_tax,
    MIN(sr.sr_return_ship_cost) AS min_ship_cost
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_ret.d_year >= 2000
  AND d_cc_open.d_year >= 1995
GROUP BY
    cc.cc_call_center_id,
    cc.cc_company_name,
    d_cc_open.d_year,
    s.s_store_id,
    s.s_store_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    t.t_hour
ORDER BY total_net_loss DESC
LIMIT 100
