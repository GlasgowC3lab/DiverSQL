SELECT
    (d.d_year * 100 + d.d_month_seq) AS year_month,
    r.r_reason_desc,
    hd_ret.hd_income_band_sk AS ret_income_band,
    hd_ref.hd_income_band_sk AS ref_income_band,
    s.s_state,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_fee) AS avg_fee,
    SUM(CASE WHEN d.d_weekend = 'Y' THEN wr.wr_return_amt ELSE 0 END) AS weekend_return_amount,
    SUM(CASE WHEN s.s_gmt_offset > 0 THEN wr.wr_return_amt ELSE 0 END) AS positive_gmt_return_amount,
    SUM(CASE WHEN hd_ret.hd_vehicle_count > hd_ref.hd_vehicle_count THEN wr.wr_return_amt ELSE 0 END) AS vehicle_mismatch_return_amount
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2010 AND 2022
GROUP BY
    (d.d_year * 100 + d.d_month_seq),
    r.r_reason_desc,
    hd_ret.hd_income_band_sk,
    hd_ref.hd_income_band_sk,
    s.s_state
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY total_return_amount DESC
LIMIT 100
