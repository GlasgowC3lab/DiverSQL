SELECT
    cp.cp_department,
    cp.cp_catalog_page_number,
    dd_start.d_year AS start_year,
    dd_end.d_year AS end_year,
    dd_start.d_month_seq AS start_month_seq,
    dd_end.d_month_seq AS end_month_seq,
    s.s_state,
    s.s_market_id,
    hd_ret.hd_income_band_sk AS returning_income_band,
    hd_ref.hd_income_band_sk AS refunded_income_band,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_net_loss) AS total_net_loss,
    date_diff('day', dd_start.d_date, dd_end.d_date) AS catalog_page_duration_days,
    SUM(CASE WHEN wr.wr_return_tax > 0 THEN wr.wr_return_tax ELSE 0 END) AS total_return_tax
FROM catalog_page cp
JOIN date_dim dd_start
    ON cp.cp_start_date_sk = dd_start.d_date_sk
JOIN date_dim dd_end
    ON cp.cp_end_date_sk = dd_end.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = dd_end.d_date_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = dd_end.d_date_sk
WHERE wr.wr_returned_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
GROUP BY
    cp.cp_department,
    cp.cp_catalog_page_number,
    dd_start.d_year,
    dd_end.d_year,
    dd_start.d_month_seq,
    dd_end.d_month_seq,
    s.s_state,
    s.s_market_id,
    hd_ret.hd_income_band_sk,
    hd_ref.hd_income_band_sk,
    dd_start.d_date,
    dd_end.d_date
ORDER BY total_return_amount DESC
LIMIT 100
