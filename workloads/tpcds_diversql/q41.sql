WITH high_refunds AS (
  SELECT
    c.c_customer_id AS customer_id,
    ca.ca_country AS country,
    i.i_category AS category,
    SUM(wr.wr_return_amt) AS total_return
  FROM web_returns wr
  JOIN customer c
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
  WHERE wr.wr_return_amt > 100
  GROUP BY c.c_customer_id, ca.ca_country, i.i_category
),
low_refunds AS (
  SELECT
    c.c_customer_id AS customer_id,
    ca.ca_country AS country,
    i.i_category AS category
  FROM web_returns wr
  JOIN customer c
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
  JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
  WHERE wr.wr_return_amt <= 100
  GROUP BY c.c_customer_id, ca.ca_country, i.i_category
),
high_keys AS (
  SELECT DISTINCT customer_id, country, category
  FROM high_refunds
),
low_keys AS (
  SELECT DISTINCT customer_id, country, category
  FROM low_refunds
),
high_not_low_keys AS (
  SELECT hk.customer_id, hk.country, hk.category
  FROM high_keys hk
  EXCEPT
  SELECT lk.customer_id, lk.country, lk.category
  FROM low_keys lk
)
SELECT
  COALESCE(d.country, 'ALL') AS country,
  COALESCE(d.category, 'ALL') AS category,
  SUM(hr.total_return) AS total_return_amount
FROM high_not_low_keys d
JOIN high_refunds hr
  ON d.customer_id = hr.customer_id
 AND d.country = hr.country
 AND d.category = hr.category
GROUP BY ROLLUP (d.country, d.category)
ORDER BY country, category
LIMIT 100
