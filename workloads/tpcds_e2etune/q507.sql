WITH demographic_returns AS (
  SELECT
    dr_returning.cd_gender AS gender,
    dr_returning.cd_marital_status AS marital_status,
    dr_returning.cd_education_status AS education_status,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_refunded_cash) AS total_refunded_cash,
    SUM(CASE WHEN dr_refunded.cd_gender = dr_returning.cd_gender THEN 1 ELSE 0 END) AS same_gender_refunds
  FROM web_returns wr
  JOIN customer_demographics dr_returning
    ON wr.wr_returning_cdemo_sk = dr_returning.cd_demo_sk
  JOIN customer_demographics dr_refunded
    ON wr.wr_refunded_cdemo_sk = dr_refunded.cd_demo_sk
  WHERE wr.wr_returned_date_sk BETWEEN 2451545 AND 2451910
    AND dr_returning.cd_credit_rating = 'Excellent'
  GROUP BY dr_returning.cd_gender, dr_returning.cd_marital_status, dr_returning.cd_education_status
  HAVING COUNT(*) > 50
)
SELECT
  gender,
  marital_status,
  education_status,
  num_returns,
  total_return_amount,
  avg_return_quantity,
  total_refunded_cash,
  CASE WHEN total_return_amount = 0 THEN 0 ELSE total_refunded_cash / total_return_amount END AS refund_rate,
  same_gender_refunds,
  same_gender_refunds * 1.0 / num_returns AS same_gender_refund_ratio,
  RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank
FROM demographic_returns
ORDER BY total_return_amount DESC
LIMIT 10
