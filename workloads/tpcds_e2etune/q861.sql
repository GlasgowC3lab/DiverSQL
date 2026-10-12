SELECT
    rd.cd_marital_status,
    rd.cd_education_status,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    ROUND(AVG(wr.wr_return_amt) / NULLIF(SUM(wr.wr_net_loss), 0), 2) AS avg_return_to_loss_ratio
FROM web_returns wr
JOIN customer_demographics rd
    ON wr.wr_returning_cdemo_sk = rd.cd_demo_sk
JOIN customer_demographics fd
    ON wr.wr_refunded_cdemo_sk = fd.cd_demo_sk
WHERE
    rd.cd_purchase_estimate > 1500
    AND fd.cd_dep_employed_count >= 1
    AND wr.wr_net_loss > 0
GROUP BY
    rd.cd_marital_status,
    rd.cd_education_status
HAVING
    COUNT(*) >= 10
ORDER BY
    total_net_loss DESC
LIMIT 100
