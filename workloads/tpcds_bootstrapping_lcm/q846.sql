SELECT
    d.d_year,
    sm.sm_type,
    s.s_state,
    CASE
        WHEN d.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter_label,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_count,
    COUNT(DISTINCT wr.wr_order_number) AS web_order_count,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(cr.cr_fee) + SUM(wr.wr_fee) AS total_fees,
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
    (SUM(cr.cr_return_amount) - SUM(wr.wr_return_amt)) AS net_return_difference,
    CASE
        WHEN SUM(wr.wr_fee) = 0 THEN NULL
        ELSE SUM(cr.cr_fee) / SUM(wr.wr_fee)
    END AS fee_ratio
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2020
GROUP BY
    d.d_year,
    sm.sm_type,
    s.s_state,
    CASE
        WHEN d.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END
ORDER BY total_net_loss DESC
LIMIT 100
