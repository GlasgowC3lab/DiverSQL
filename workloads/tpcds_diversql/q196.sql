SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  SUM(wr.wr_return_amt) AS total_return_amount
FROM web_returns AS wr
JOIN customer AS c
  ON wr.wr_returning_customer_sk = c.c_customer_sk
WHERE c.c_birth_month = 5
  AND wr.wr_return_ship_cost > 100
GROUP BY
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name
ORDER BY total_return_amount DESC
LIMIT 10
