WITH agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education,
        cd.cd_credit_rating AS credit_rating,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_quantity) AS avg_return_quantity,
        SUM(CASE WHEN sr.sr_return_amt > 100 THEN 1 ELSE 0 END) AS high_value_returns
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 1965
      AND c.c_preferred_cust_flag = 'Y'
      AND sr.sr_returned_date_sk >= 2452500
    GROUP BY GROUPING SETS (
        (cd.cd_gender, cd.cd_education_status, cd.cd_credit_rating),
        (cd.cd_gender, cd.cd_education_status),
        (cd.cd_gender)
    )
    HAVING SUM(sr.sr_return_amt) > 1000
)
SELECT
    gender,
    education,
    credit_rating,
    distinct_customers,
    total_return_amount,
    total_net_loss,
    avg_return_quantity,
    high_value_returns,
    RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM agg
ORDER BY total_return_amount DESC
LIMIT 20
