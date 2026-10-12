WITH
  store_agg AS (
    SELECT
      c.c_customer_sk,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
      c.c_first_name,
      c.c_last_name,
      c.c_email_address,
      regexp_extract(c.c_email_address, '@(.+)$') AS email_domain,
      SUM(s.ss_net_paid_inc_tax) AS store_net_paid,
      COUNT(*) AS store_txn_cnt
    FROM store_sales s
    JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
    WHERE c.c_last_name LIKE 'S%'
      AND regexp_like(c.c_email_address, '^.*@.+\\.com$')
    GROUP BY
      c.c_customer_sk,
      CONCAT(c.c_first_name, ' ', c.c_last_name),
      c.c_first_name,
      c.c_last_name,
      c.c_email_address,
      regexp_extract(c.c_email_address, '@(.+)$')
  ),
  web_agg AS (
    SELECT
      c.c_customer_sk,
      SUM(w.ws_net_paid_inc_ship_tax) AS web_net_paid,
      COUNT(*) AS web_txn_cnt
    FROM web_sales w
    JOIN customer c ON w.ws_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(c.c_email_address, '^.*@.+\\.com$')
      AND substring(c.c_login, 1, 1) = 'a'
    GROUP BY c.c_customer_sk
  ),
  combined AS (
    SELECT
      s.c_customer_sk,
      s.full_name,
      s.c_first_name,
      s.c_last_name,
      s.c_email_address,
      s.email_domain,
      s.store_net_paid,
      s.store_txn_cnt,
      COALESCE(w.web_net_paid, 0) AS web_net_paid,
      COALESCE(w.web_txn_cnt, 0) AS web_txn_cnt,
      (s.store_net_paid + COALESCE(w.web_net_paid, 0)) AS total_net_paid
    FROM store_agg s
    LEFT JOIN web_agg w ON s.c_customer_sk = w.c_customer_sk
  ),
  ranked AS (
    SELECT
      *,
      ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS global_row_num,
      ROW_NUMBER() OVER (PARTITION BY email_domain ORDER BY total_net_paid DESC) AS domain_rank
    FROM combined
  )
SELECT
  global_row_num,
  c_customer_sk,
  full_name,
  c_first_name,
  c_last_name,
  c_email_address,
  email_domain,
  store_net_paid,
  web_net_paid,
  total_net_paid,
  domain_rank
FROM ranked
WHERE domain_rank <= 5
ORDER BY total_net_paid DESC
LIMIT 100
