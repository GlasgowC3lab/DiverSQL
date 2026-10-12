WITH
  store_agg AS (
    SELECT
      ss.ss_customer_sk AS cust_sk,
      SUM(ss.ss_net_paid) AS store_total,
      COUNT(DISTINCT ss.ss_item_sk) AS store_distinct_items,
      COUNT(DISTINCT d.d_month_seq) AS store_distinct_months
    FROM
      tpcds.store_sales ss
      JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2001
    GROUP BY
      ss.ss_customer_sk
  ),
  web_agg AS (
    SELECT
      ws.ws_bill_customer_sk AS cust_sk,
      SUM(ws.ws_net_paid) AS web_total,
      COUNT(DISTINCT ws.ws_item_sk) AS web_distinct_items,
      COUNT(DISTINCT d.d_month_seq) AS web_distinct_months
    FROM
      tpcds.web_sales ws
      JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
      d.d_year = 2001
    GROUP BY
      ws.ws_bill_customer_sk
  ),
  full_joined AS (
    SELECT
      COALESCE(sa.cust_sk, wa.cust_sk) AS cust_sk,
      sa.store_total,
      wa.web_total,
      sa.store_distinct_items,
      wa.web_distinct_items,
      sa.store_distinct_months,
      wa.web_distinct_months
    FROM
      store_agg sa
      FULL OUTER JOIN web_agg wa ON sa.cust_sk = wa.cust_sk
  ),
  intersect_keys AS (
    SELECT cust_sk FROM store_agg
    INTERSECT
    SELECT cust_sk FROM web_agg
  ),
  unioned AS (
    SELECT cust_sk, store_total, store_distinct_items FROM store_agg
    UNION
    SELECT cust_sk, web_total AS store_total, web_distinct_items AS store_distinct_items FROM web_agg
  )
SELECT
  CASE WHEN GROUPING(fj.cust_sk) = 1 THEN NULL ELSE fj.cust_sk END AS cust_sk,
  SUM(fj.store_total) AS sum_store_total,
  SUM(fj.web_total) AS sum_web_total,
  SUM(fj.store_distinct_items) AS sum_store_distinct_items,
  SUM(fj.web_distinct_items) AS sum_web_distinct_items,
  SUM(fj.store_distinct_months) AS sum_store_distinct_months,
  SUM(fj.web_distinct_months) AS sum_web_distinct_months,
  COUNT(DISTINCT fj.cust_sk) AS distinct_cust_cnt,
  COUNT(DISTINCT fj.store_distinct_items) AS distinct_store_item_cnt,
  COUNT(DISTINCT fj.web_distinct_items) AS distinct_web_item_cnt
FROM
  full_joined fj
WHERE
  fj.cust_sk IN (SELECT cust_sk FROM intersect_keys)
GROUP BY
  GROUPING SETS ( (fj.cust_sk), () )
ORDER BY
  cust_sk
OFFSET 0
LIMIT 100
