SELECT
    d_return.d_year,
    d_return.d_month_seq,
    s.s_state,
    i.i_category,
    CASE
        WHEN hd_refunded.hd_income_band_sk >= 7 THEN 'high_income'
        WHEN hd_refunded.hd_income_band_sk >= 4 THEN 'mid_income'
        ELSE 'low_income'
    END AS refunded_income_bracket,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN hd_returning.hd_vehicle_count > 2 THEN wr.wr_return_amt ELSE 0 END) AS multi_vehicle_return_amount,
    MIN(d_return.d_date) AS first_return_date,
    MAX(d_return.d_date) AS last_return_date,
    SUM(wr.wr_return_amt) * 1.1 AS adjusted_return_amount,
    (SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_amt), 0)) AS net_loss_ratio
FROM web_returns wr
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_return.d_year BETWEEN 2000 AND 2005
  AND i.i_category IS NOT NULL
GROUP BY
    d_return.d_year,
    d_return.d_month_seq,
    s.s_state,
    i.i_category,
    CASE
        WHEN hd_refunded.hd_income_band_sk >= 7 THEN 'high_income'
        WHEN hd_refunded.hd_income_band_sk >= 4 THEN 'mid_income'
        ELSE 'low_income'
    END
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
