SELECT
    d.d_year,
    d.d_month_seq,
    s.s_state,
    r.r_reason_desc,
    cd_refunded.cd_gender,
    cd_returning.cd_education_status,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS sum_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_quantity,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(CASE WHEN cd_refunded.cd_credit_rating = 'Excellent' THEN wr.wr_return_amt ELSE 0 END) AS excellent_credit_return_amt
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND s.s_state IN ('CA', 'NY', 'TX')
  AND r.r_reason_desc LIKE '%defect%'
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_state,
    r.r_reason_desc,
    cd_refunded.cd_gender,
    cd_returning.cd_education_status
HAVING COUNT(*) > 100
ORDER BY total_returns DESC
LIMIT 100
