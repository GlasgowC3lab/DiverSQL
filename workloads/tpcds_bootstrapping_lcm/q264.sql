SELECT
    d.d_current_year AS year,
    d.d_current_month AS month,
    d.d_dow AS day_of_week,
    (d.d_month_seq % 3) AS month_mod_group,
    t.t_shift AS time_shift,
    r.r_reason_desc AS reason,
    s.s_state AS state,
    CASE
        WHEN wr.wr_return_quantity >= 10 THEN 'Bulk'
        WHEN wr.wr_return_quantity BETWEEN 2 AND 9 THEN 'Multiple'
        ELSE 'Single'
    END AS return_category,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    ROUND(100.0 * SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_amt), 0), 2) AS net_loss_percent,
    AVG(wr.wr_return_quantity) AS avg_quantity,
    SUM(wr.wr_fee) AS total_fee,
    ROUND(SUM(wr.wr_fee) / NULLIF(COUNT(*), 0), 2) AS avg_fee_per_return,
    SUM(wr.wr_return_tax) AS total_tax
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_current_year = '2023'
  AND t.t_shift IS NOT NULL
GROUP BY
    d.d_current_year,
    d.d_current_month,
    d.d_dow,
    (d.d_month_seq % 3),
    t.t_shift,
    r.r_reason_desc,
    s.s_state,
    CASE
        WHEN wr.wr_return_quantity >= 10 THEN 'Bulk'
        WHEN wr.wr_return_quantity BETWEEN 2 AND 9 THEN 'Multiple'
        ELSE 'Single'
    END
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY total_net_loss DESC
LIMIT 200
