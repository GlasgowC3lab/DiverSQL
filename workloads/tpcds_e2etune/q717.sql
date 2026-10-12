SELECT
    education_status,
    credit_rating,
    num_returns,
    total_return_amt,
    avg_return_amt,
    total_net_loss,
    avg_net_loss,
    loss_ratio,
    RANK() OVER (ORDER BY avg_return_amt DESC) AS education_rank
FROM (
    SELECT
        cd.cd_education_status AS education_status,
        cd.cd_credit_rating AS credit_rating,
        COUNT(*) AS num_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_net_loss) AS avg_net_loss,
        ROUND(AVG(sr.sr_net_loss) / NULLIF(AVG(sr.sr_return_amt), 0), 4) AS loss_ratio
    FROM store_returns sr
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND cd.cd_purchase_estimate >= 1500
      AND cd.cd_education_status IN ('College', '4 yr Degree', '2 yr Degree')
    GROUP BY cd.cd_education_status, cd.cd_credit_rating
    HAVING COUNT(*) > 10
) t
ORDER BY avg_return_amt DESC
LIMIT 5
