WITH customer_return_agg AS (
    SELECT
        sr.sr_cdemo_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_events,
        SUM(sr.sr_return_quantity) AS total_qty,
        AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
      AND sr.sr_returned_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY sr.sr_cdemo_sk
)
SELECT
    cd.cd_credit_rating,
    cd.cd_education_status,
    cd.cd_gender,
    CASE
        WHEN cd.cd_dep_college_count > 0 THEN 'CollegeDep'
        ELSE 'NoCollegeDep'
    END AS college_dependency_flag,
    COUNT(*) AS demo_count,
    SUM(cra.total_return_amt) AS sum_return_amt,
    ROUND(AVG(cra.total_net_loss), 2) AS avg_net_loss,
    SUM(cra.total_qty) AS sum_return_qty,
    ROUND(AVG(cra.avg_return_amt_inc_tax), 2) AS avg_return_amt_inc_tax
FROM customer_return_agg cra
JOIN customer_demographics cd
    ON cra.sr_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_purchase_estimate >= 1500
  AND cd.cd_credit_rating IN ('Good', 'Low Risk', 'High Risk')
  AND cd.cd_marital_status <> 'U'
GROUP BY cd.cd_credit_rating,
         cd.cd_education_status,
         cd.cd_gender,
         CASE
            WHEN cd.cd_dep_college_count > 0 THEN 'CollegeDep'
            ELSE 'NoCollegeDep'
         END
HAVING SUM(cra.total_return_amt) > 50000
ORDER BY sum_return_amt DESC
LIMIT 25
