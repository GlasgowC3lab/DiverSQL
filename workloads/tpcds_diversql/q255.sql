WITH refunded AS (
  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    wr.wr_returned_date_sk,
    wr.wr_return_amt,
    wr.wr_refunded_cash
  FROM
    customer c
    FULL OUTER JOIN (
      SELECT * FROM web_returns TABLESAMPLE BERNOULLI (5)
    ) wr
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
  WHERE
    c.c_birth_country = 'KOREA'
    AND wr.wr_refunded_cash > 100
    AND c.c_first_shipto_date_sk BETWEEN 2450000 AND 2452000
),
returning AS (
  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_country,
    wr.wr_returned_date_sk,
    wr.wr_return_amt,
    wr.wr_refunded_cash
  FROM (
    SELECT * FROM web_returns TABLESAMPLE BERNOULLI (5)
  ) wr
  FULL OUTER JOIN customer c
    ON wr.wr_returning_customer_sk = c.c_customer_sk
  WHERE
    c.c_salutation = 'Dr.'
    AND wr.wr_return_amt > 200
    AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2453000
)
SELECT
  c_customer_sk,
  c_first_name,
  c_last_name,
  c_birth_country,
  wr_returned_date_sk,
  wr_return_amt,
  wr_refunded_cash,
  return_type
FROM (
  SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    c_birth_country,
    wr_returned_date_sk,
    wr_return_amt,
    wr_refunded_cash,
    'refunded' AS return_type
  FROM refunded
  UNION ALL
  SELECT
    c_customer_sk,
    c_first_name,
    c_last_name,
    c_birth_country,
    wr_returned_date_sk,
    wr_return_amt,
    wr_refunded_cash,
    'returning' AS return_type
  FROM returning
) t
ORDER BY wr_returned_date_sk DESC, c_customer_sk
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
