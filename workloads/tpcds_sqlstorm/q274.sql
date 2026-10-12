WITH
sales_unified AS (
  SELECT
    ws.ws_bill_customer_sk AS c_customer_sk,
    ws.ws_sold_date_sk AS d_date_sk,
    ws.ws_net_paid AS sales_amt,
    'WEB' AS channel
  FROM web_sales ws
  UNION ALL
  SELECT
    ss.ss_customer_sk,
    ss.ss_sold_date_sk,
    ss.ss_net_paid,
    'STORE'
  FROM store_sales ss
  UNION ALL
  SELECT
    cs.cs_bill_customer_sk,
    cs.cs_sold_date_sk,
    cs.cs_net_paid,
    'CATALOG'
  FROM catalog_sales cs
),
sales_agg AS (
  SELECT
    s.c_customer_sk,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    SUM(CASE WHEN s.channel = 'WEB' THEN s.sales_amt ELSE 0 END) AS web_sales_total,
    SUM(CASE WHEN s.channel = 'STORE' THEN s.sales_amt ELSE 0 END) AS store_sales_total,
    SUM(CASE WHEN s.channel = 'CATALOG' THEN s.sales_amt ELSE 0 END) AS catalog_sales_total,
    SUM(s.sales_amt) AS total_sales,
    COUNT(*) AS num_transactions
  FROM sales_unified s
  LEFT JOIN date_dim d ON d.d_date_sk = s.d_date_sk
  GROUP BY
    s.c_customer_sk,
    d.d_date,
    d.d_year,
    d.d_month_seq
),
returns_unified AS (
  SELECT
    wr.wr_refunded_customer_sk AS c_customer_sk,
    wr.wr_returned_date_sk AS d_date_sk,
    wr.wr_return_amt_inc_tax AS return_amt,
    'WEB' AS channel
  FROM web_returns wr
  UNION ALL
  SELECT
    sr.sr_customer_sk,
    sr.sr_returned_date_sk,
    sr.sr_return_amt_inc_tax,
    'STORE'
  FROM store_returns sr
  UNION ALL
  SELECT
    cr.cr_refunded_customer_sk,
    cr.cr_returned_date_sk,
    cr.cr_return_amt_inc_tax,
    'CATALOG'
  FROM catalog_returns cr
),
returns_agg AS (
  SELECT
    r.c_customer_sk,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    SUM(CASE WHEN r.channel = 'WEB' THEN r.return_amt ELSE 0 END) AS web_return_total,
    SUM(CASE WHEN r.channel = 'STORE' THEN r.return_amt ELSE 0 END) AS store_return_total,
    SUM(CASE WHEN r.channel = 'CATALOG' THEN r.return_amt ELSE 0 END) AS catalog_return_total,
    SUM(r.return_amt) AS total_returns,
    COUNT(*) AS num_return_transactions
  FROM returns_unified r
  LEFT JOIN date_dim d ON d.d_date_sk = r.d_date_sk
  GROUP BY
    r.c_customer_sk,
    d.d_date,
    d.d_year,
    d.d_month_seq
),
cust_sales_returns AS (
  SELECT
    COALESCE(sa.c_customer_sk, ra.c_customer_sk) AS c_customer_sk,
    COALESCE(sa.d_date, ra.d_date) AS d_date,
    COALESCE(sa.d_year, ra.d_year) AS d_year,
    COALESCE(sa.d_month_seq, ra.d_month_seq) AS d_month_seq,
    COALESCE(sa.web_sales_total, 0) AS web_sales_total,
    COALESCE(sa.store_sales_total, 0) AS store_sales_total,
    COALESCE(sa.catalog_sales_total, 0) AS catalog_sales_total,
    COALESCE(sa.total_sales, 0) AS total_sales,
    COALESCE(ra.web_return_total, 0) AS web_return_total,
    COALESCE(ra.store_return_total, 0) AS store_return_total,
    COALESCE(ra.catalog_return_total, 0) AS catalog_return_total,
    COALESCE(ra.total_returns, 0) AS total_returns,
    (COALESCE(sa.total_sales, 0) - COALESCE(ra.total_returns, 0)) AS net_total,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(sa.c_customer_sk, ra.c_customer_sk) ORDER BY COALESCE(sa.d_date, ra.d_date) DESC) AS rn_desc_date,
    RANK() OVER (PARTITION BY COALESCE(sa.c_customer_sk, ra.c_customer_sk) ORDER BY (COALESCE(sa.total_sales, 0) - COALESCE(ra.total_returns, 0)) DESC) AS sales_rank,
    PERCENT_RANK() OVER (ORDER BY (COALESCE(sa.total_sales, 0) - COALESCE(ra.total_returns, 0)) DESC) AS overall_percentile
  FROM sales_agg sa
  FULL OUTER JOIN returns_agg ra
    ON sa.c_customer_sk = ra.c_customer_sk AND sa.d_date = ra.d_date
),
customer_info AS (
  SELECT
    c.c_customer_sk,
    concat(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
    CASE
      WHEN c.c_birth_year IS NULL THEN 'UNKNOWN'
      WHEN c.c_birth_year < 1900 THEN 'PRE_1900'
      ELSE 'NORMAL'
    END AS age_bucket
  FROM customer c
),
final_combined AS (
  SELECT
    csr.c_customer_sk,
    csr.d_date,
    ci.full_name,
    ci.age_bucket,
    csr.web_sales_total,
    csr.store_sales_total,
    csr.catalog_sales_total,
    csr.web_return_total,
    csr.store_return_total,
    csr.catalog_return_total,
    csr.net_total,
    (SELECT MAX(inner_csr.net_total)
       FROM cust_sales_returns inner_csr
       WHERE inner_csr.c_customer_sk = csr.c_customer_sk
         AND inner_csr.d_date < csr.d_date) AS prev_max_net_total,
    csr.rn_desc_date,
    csr.sales_rank,
    csr.overall_percentile,
    CASE
      WHEN csr.net_total = 0 THEN NULL
      ELSE csr.net_total / NULLIF(csr.sales_rank, 0)
    END AS net_per_rank
  FROM cust_sales_returns csr
  LEFT JOIN customer_info ci ON ci.c_customer_sk = csr.c_customer_sk
  UNION ALL
  SELECT
    -1,
    DATE '1900-01-01',
    'Synthetic Customer',
    'SYNTHETIC',
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    0.0,
    NULL,
    0,
    0,
    0.0,
    NULL
)
SELECT *
FROM final_combined
WHERE
  (net_total > 1000 OR sales_rank <= 10)
  AND NOT (full_name IS NULL OR full_name = '')
  AND net_per_rank IS NOT NULL
ORDER BY overall_percentile DESC, net_total DESC
LIMIT 50
