SELECT
    d_wr.d_year * 100 + d_wr.d_month_seq AS year_month,
    s.s_state,
    cp.cp_type,
    CONCAT(cd_refunded.cd_gender, '-', cd_returning.cd_education_status) AS demo_key,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_net_loss) AS total_net_loss,
    MIN(d_cp_start.d_date) AS cp_start_date,
    MAX(d_cp_end.d_date) AS cp_end_date
FROM web_returns wr
JOIN date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_wr.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_wr.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE d_wr.d_year BETWEEN 1998 AND 2002
GROUP BY
    d_wr.d_year * 100 + d_wr.d_month_seq,
    s.s_state,
    cp.cp_type,
    CONCAT(cd_refunded.cd_gender, '-', cd_returning.cd_education_status)
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC
LIMIT 100
