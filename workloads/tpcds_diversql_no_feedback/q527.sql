WITH
  cs_agg AS (
    SELECT
      cs_bill_customer_sk AS cust_sk,
      SUM(cs_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_sales_price > 30
      AND cs_ship_date_sk BETWEEN 2450830 AND 2450840
    GROUP BY cs_bill_customer_sk
  ),
  high_store_customers AS (
    SELECT DISTINCT sr_customer_sk AS cust_sk
    FROM store_returns
    WHERE sr_net_loss > 1000
  ),
  high_web_customers AS (
    SELECT DISTINCT wr_refunded_customer_sk AS cust_sk
    FROM web_returns
    WHERE wr_net_loss > 500
  )
(
  SELECT
    c.c_customer_id,
    c.c_birth_month,
    cs.total_sales,
    cs.sales_cnt,
    SUM(sr.sr_return_amt) AS store_return_total,
    SUM(wr.wr_return_amt) AS web_return_total,
    COUNT(DISTINCT cs.cust_sk) AS distinct_sales_customers
  FROM cs_agg cs
  JOIN customer c ON cs.cust_sk = c.c_customer_sk
  LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
  LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
  WHERE c.c_birth_month IN (3, 4, 10, 11)
    AND c.c_first_shipto_date_sk BETWEEN 2450420 AND 2451500
    AND c.c_preferred_cust_flag = 'Y'
    AND EXISTS (SELECT 1 FROM high_store_customers hsc WHERE hsc.cust_sk = c.c_customer_sk)
    AND EXISTS (SELECT 1 FROM high_web_customers hwc WHERE hwc.cust_sk = c.c_customer_sk)
  GROUP BY
    c.c_customer_id,
    c.c_birth_month,
    cs.total_sales,
    cs.sales_cnt
)
INTERSECT
(
  SELECT
    c2.c_customer_id,
    c2.c_birth_month,
    cs2.total_sales,
    cs2.sales_cnt,
    SUM(sr2.sr_return_amt) AS store_return_total,
    SUM(wr2.wr_return_amt) AS web_return_total,
    COUNT(DISTINCT cs2.cust_sk) AS distinct_sales_customers
  FROM cs_agg cs2
  JOIN customer c2 ON cs2.cust_sk = c2.c_customer_sk
  LEFT JOIN store_returns sr2 ON sr2.sr_customer_sk = c2.c_customer_sk
  LEFT JOIN web_returns wr2 ON wr2.wr_refunded_customer_sk = c2.c_customer_sk
  WHERE c2.c_birth_month IN (3, 4, 10, 11)
    AND c2.c_first_shipto_date_sk BETWEEN 2450420 AND 2451500
    AND c2.c_preferred_cust_flag = 'Y'
    AND EXISTS (SELECT 1 FROM high_store_customers hsc2 WHERE hsc2.cust_sk = c2.c_customer_sk)
    AND EXISTS (SELECT 1 FROM high_web_customers hwc2 WHERE hwc2.cust_sk = c2.c_customer_sk)
  GROUP BY
    c2.c_customer_id,
    c2.c_birth_month,
    cs2.total_sales,
    cs2.sales_cnt
)
ORDER BY total_sales DESC
LIMIT 100
