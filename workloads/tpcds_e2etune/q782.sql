SELECT
    cd_ref.cd_education_status,
    cd_ref.cd_credit_rating,
    cd_ref.cd_gender,
    COUNT(*) AS num_returns,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    ROUND(SUM(wr.wr_fee) / NULLIF(SUM(wr.wr_net_loss), 0), 2) AS fee_to_loss_ratio
FROM web_returns wr
JOIN customer_demographics cd_ref
    ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN customer_demographics cd_ret
    ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
WHERE cd_ref.cd_credit_rating IN ('High Risk', 'Low Risk')
  AND cd_ref.cd_education_status IN ('College', '4 yr Degree')
  AND wr.wr_return_quantity >= 2
  AND wr.wr_return_amt > 1000
GROUP BY cd_ref.cd_education_status, cd_ref.cd_credit_rating, cd_ref.cd_gender
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 20
