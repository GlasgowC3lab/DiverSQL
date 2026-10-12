SELECT
    d.d_year,
    d.d_quarter_name,
    r.r_reason_desc,
    s.s_division_name,
    ws.web_country,
    CASE
        WHEN d.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS fiscal_quarter,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_tax,
    AVG(wr.wr_net_loss) AS avg_net_loss,
    SUM(CASE WHEN wr.wr_return_amt_inc_tax > 200 THEN 1 ELSE 0 END) AS high_value_returns
FROM date_dim d
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2025
GROUP BY
    d.d_year,
    d.d_quarter_name,
    r.r_reason_desc,
    s.s_division_name,
    ws.web_country,
    CASE
        WHEN d.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
