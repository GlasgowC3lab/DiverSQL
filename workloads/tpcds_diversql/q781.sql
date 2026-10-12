WITH
  store_ret AS (
    SELECT
      ca.ca_zip,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS return_cnt
    FROM tpcds.store_returns AS sr
    JOIN tpcds.customer_address AS ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics AS cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_return_amt > 100
      AND cd.cd_gender = 'M'
    GROUP BY ca.ca_zip
    HAVING SUM(sr.sr_return_amt) > 500
  ),
  web_sales_agg AS (
    SELECT
      ca.ca_zip,
      SUM(ws.ws_ext_sales_price) AS total_sales_amt,
      COUNT(*) AS sales_cnt
    FROM tpcds.web_sales AS ws
    JOIN tpcds.customer_address AS ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics AS cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_ext_sales_price > 200
      AND cd.cd_gender = 'F'
    GROUP BY ca.ca_zip
    HAVING SUM(ws.ws_ext_sales_price) > 1000
  ),
  zip_intersect AS (
    SELECT ca_zip FROM store_ret
    INTERSECT
    SELECT ca_zip FROM web_sales_agg
  )
SELECT DISTINCT
  zi.ca_zip,
  sr.total_return_amt,
  ws.total_sales_amt,
  (
    SELECT COUNT(DISTINCT sr2.sr_customer_sk)
    FROM tpcds.store_returns AS sr2
    JOIN tpcds.customer_address AS ca2 ON sr2.sr_addr_sk = ca2.ca_address_sk
    WHERE ca2.ca_zip = zi.ca_zip
  ) AS distinct_return_customers,
  SUM(sr.total_return_amt + ws.total_sales_amt) OVER (
    ORDER BY zi.ca_zip
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total_amt,
  LAG(sr.total_return_amt) OVER (ORDER BY zi.ca_zip) AS prev_return_amt
FROM zip_intersect AS zi
JOIN store_ret AS sr ON zi.ca_zip = sr.ca_zip
JOIN web_sales_agg AS ws ON zi.ca_zip = ws.ca_zip
ORDER BY zi.ca_zip
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
