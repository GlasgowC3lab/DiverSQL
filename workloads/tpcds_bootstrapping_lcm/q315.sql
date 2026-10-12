SELECT
    d.d_year,
    d.d_month_seq,
    s.s_state,
    r.r_reason_desc,
    cd.cd_gender,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_fee) AS avg_fee,
    SUM(CASE WHEN cd.cd_credit_rating = 'Excellent' THEN 1 ELSE 0 END) AS excellent_credit_count,
    SUM(wr.wr_return_amt * wr.wr_return_quantity) AS weighted_return_amount,
    SUM(wr.wr_net_loss) / NULLIF(COUNT(*), 0) AS avg_net_loss_per_return,
    SUM(CASE WHEN cd.cd_education_status = 'College' THEN wr.wr_return_amt ELSE 0 END) AS college_education_return_amount
FROM web_returns wr
JOIN date_dim d
  ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd
  ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE s.s_floor_space > 20000
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_state,
    r.r_reason_desc,
    cd.cd_gender
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
