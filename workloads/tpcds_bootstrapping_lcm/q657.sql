SELECT
    d.d_quarter_name,
    d.d_year,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    hd_refunded.hd_income_band_sk AS refunded_income_band,
    hd_returning.hd_income_band_sk AS returning_income_band,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    SUM(wr.wr_fee) AS total_fee,
    ROUND(AVG(wr.wr_return_amt) * 100 / NULLIF(SUM(wr.wr_return_amt), 0), 2) AS avg_return_percent_of_total,
    MAX(wr.wr_returned_date_sk) AS max_return_date_sk,
    MIN(wr.wr_returned_date_sk) AS min_return_date_sk
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND s.s_state IN ('CA', 'NY', 'TX')
GROUP BY
    d.d_quarter_name,
    d.d_year,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    hd_refunded.hd_income_band_sk,
    hd_returning.hd_income_band_sk
ORDER BY
    d.d_year,
    d.d_quarter_name,
    total_net_loss DESC
LIMIT 200
