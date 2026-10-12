SELECT
    d.d_year,
    d.d_month_seq,
    d.d_week_seq % 4 AS week_mod,
    CASE
        WHEN hd_returning.hd_income_band_sk >= 8 THEN 'HIGH_INCOME'
        WHEN hd_returning.hd_income_band_sk >= 5 THEN 'MID_INCOME'
        ELSE 'LOW_INCOME'
    END AS returning_income_group,
    CASE
        WHEN hd_refunded.hd_income_band_sk >= 8 THEN 'HIGH_INCOME'
        WHEN hd_refunded.hd_income_band_sk >= 5 THEN 'MID_INCOME'
        ELSE 'LOW_INCOME'
    END AS refunded_income_group,
    s.s_state,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    SUM(wr.wr_return_amt_inc_tax) - SUM(wr.wr_return_tax) AS sum_return_excluding_tax,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(CASE WHEN wr.wr_fee > 0 THEN wr.wr_fee ELSE 0 END) AS total_fee
FROM date_dim d
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN household_demographics hd_returning ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN household_demographics hd_refunded ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2020
GROUP BY
    d.d_year,
    d.d_month_seq,
    d.d_week_seq % 4,
    CASE
        WHEN hd_returning.hd_income_band_sk >= 8 THEN 'HIGH_INCOME'
        WHEN hd_returning.hd_income_band_sk >= 5 THEN 'MID_INCOME'
        ELSE 'LOW_INCOME'
    END,
    CASE
        WHEN hd_refunded.hd_income_band_sk >= 8 THEN 'HIGH_INCOME'
        WHEN hd_refunded.hd_income_band_sk >= 5 THEN 'MID_INCOME'
        ELSE 'LOW_INCOME'
    END,
    s.s_state
HAVING COUNT(*) > 10
ORDER BY d.d_year DESC, total_return_amount DESC
LIMIT 100
