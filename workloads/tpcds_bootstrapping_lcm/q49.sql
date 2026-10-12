SELECT
    cp.cp_type,
    r.r_reason_desc,
    s.s_division_name,
    d_end.d_year,
    d_end.d_month_seq AS return_month,
    d_start.d_month_seq AS catalog_start_month,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(CASE WHEN wr.wr_return_amt > 1000 THEN 1 ELSE 0 END) AS high_value_returns,
    CASE WHEN SUM(wr.wr_net_loss) > 10000 THEN 'YES' ELSE 'NO' END AS high_loss_flag
FROM catalog_page cp
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_end.d_date_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
WHERE d_end.d_year >= 2020
GROUP BY
    cp.cp_type,
    r.r_reason_desc,
    s.s_division_name,
    d_end.d_year,
    d_end.d_month_seq,
    d_start.d_month_seq
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
