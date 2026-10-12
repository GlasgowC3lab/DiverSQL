WITH
  catalog_agg AS (
    SELECT
      c.c_customer_sk,
      c.c_email_address,
      ca.ca_city,
      i.i_item_desc,
      SUM(cr.cr_return_amount) AS total_return_amt
    FROM catalog_returns cr
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    WHERE regexp_like(c.c_email_address, '^.+@[^@]+\\.com$')
      AND ca.ca_city LIKE '%York%'
    GROUP BY
      c.c_customer_sk,
      c.c_email_address,
      ca.ca_city,
      i.i_item_desc
  ),
  web_customers AS (
    SELECT DISTINCT c.c_customer_sk
    FROM web_returns wr
    JOIN customer c
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
  ),
  catalog_only_customers AS (
    SELECT c_customer_sk
    FROM catalog_agg
    EXCEPT
    SELECT c_customer_sk
    FROM web_customers
  )
SELECT
  ca.c_customer_sk,
  ca.c_email_address,
  CONCAT(regexp_extract(ca.c_email_address, '@([^.]*)\\.', 1), '-customer') AS email_tag,
  ca.ca_city,
  ca.total_return_amt,
  regexp_extract(i.i_item_desc, '^([^ ]+)', 1) AS item_desc_first_word
FROM catalog_agg ca
JOIN catalog_only_customers diff
  ON ca.c_customer_sk = diff.c_customer_sk
JOIN item i
  ON i.i_item_desc = ca.i_item_desc
ORDER BY ca.total_return_amt DESC
LIMIT 100
