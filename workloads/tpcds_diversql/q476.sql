WITH sr AS (
  SELECT
    sr.sr_returned_date_sk AS return_date_sk,
    d.d_year AS year,
    sr.sr_return_amt AS return_amt,
    sr.sr_net_loss AS net_loss,
    i.i_category AS category,
    cd.cd_gender AS gender,
    r.r_reason_desc AS reason_desc,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE i.i_item_desc LIKE '%test%'
    AND regexp_like(i.i_item_desc, '\\d{3}')
),
wr AS (
  SELECT
    wr.wr_returned_date_sk AS return_date_sk,
    d.d_year AS year,
    wr.wr_return_amt AS return_amt,
    wr.wr_net_loss AS net_loss,
    i.i_category AS category,
    cd.cd_gender AS gender,
    r.r_reason_desc AS reason_desc,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  WHERE i.i_item_desc LIKE '%test%'
    AND regexp_like(i.i_item_desc, '\\d{3}')
),
combined AS (
  SELECT
    COALESCE(sr.return_date_sk, wr.return_date_sk) AS return_date_sk,
    COALESCE(sr.year, wr.year) AS year,
    COALESCE(sr.category, wr.category) AS category,
    COALESCE(sr.gender, wr.gender) AS gender,
    COALESCE(sr.reason_desc, wr.reason_desc) AS reason_desc,
    COALESCE(sr.return_amt, 0) + COALESCE(wr.return_amt, 0) AS total_return_amt,
    COALESCE(sr.net_loss, 0) + COALESCE(wr.net_loss, 0) AS total_net_loss,
    COALESCE(sr.customer_name, wr.customer_name) AS customer_name
  FROM sr
  FULL OUTER JOIN wr
    ON sr.return_date_sk = wr.return_date_sk
)
SELECT
  year,
  category,
  gender,
  reason_desc,
  SUM(total_return_amt) AS sum_return_amount,
  SUM(total_net_loss) AS sum_net_loss,
  COUNT(DISTINCT customer_name) AS distinct_customers,
  CASE
    WHEN SUM(total_return_amt) > 1000 THEN 'High'
    ELSE 'Low'
  END AS return_level
FROM combined
GROUP BY CUBE (year, category, gender, reason_desc)
HAVING SUM(total_return_amt) IS NOT NULL
ORDER BY sum_return_amount DESC
OFFSET 0
LIMIT 100
