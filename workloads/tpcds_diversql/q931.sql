WITH
  filtered_customers AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      ca.ca_address_id,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
      SUBSTRING(ca.ca_street_number FROM 1 FOR 3) AS street_prefix
    FROM customer c
    JOIN customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE REGEXP_LIKE(c.c_email_address, '^[A-Z0-9._%+-]+@example\\.com$')
  ),
  web_pages_filtered AS (
    SELECT
      wp.wp_web_page_sk,
      wp.wp_url,
      wp.wp_type,
      wp.wp_customer_sk,
      CASE
        WHEN REGEXP_LIKE(wp.wp_url, '^https?://.*\\.com/.*$') THEN 'COM'
        ELSE 'OTHER'
      END AS url_domain_flag
    FROM web_page wp
    WHERE wp.wp_url LIKE '%promo%'
  ),
  full_join_cp AS (
    SELECT
      COALESCE(c.c_customer_sk, wp.wp_customer_sk) AS customer_sk,
      c.c_customer_id,
      c.full_name,
      wp.wp_web_page_sk,
      wp.wp_url,
      wp.url_domain_flag
    FROM filtered_customers c
    FULL OUTER JOIN web_pages_filtered wp
      ON c.c_customer_sk = wp.wp_customer_sk
  ),
  store_sales_agg AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      SUM(ss.ss_net_paid) AS total_net_paid,
      SUM(ss.ss_net_profit) AS total_net_profit,
      COUNT(*) AS txn_count
    FROM store s
    JOIN store_sales ss
      ON s.s_store_sk = ss.ss_store_sk
    WHERE ss.ss_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2002
          )
      AND s.s_store_sk IN (
            SELECT ss2.ss_store_sk FROM store_sales ss2 WHERE ss2.ss_quantity > 5
          )
    GROUP BY s.s_store_sk, s.s_store_name
    HAVING SUM(ss.ss_net_profit) > 0
  ),
  store_rank AS (
    SELECT
      *,
      ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM store_sales_agg
  )
SELECT DISTINCT
  fjc.customer_sk,
  fjc.c_customer_id,
  fjc.full_name,
  fjc.wp_url,
  fjc.url_domain_flag,
  sr.s_store_name,
  sr.total_net_paid,
  sr.total_net_profit,
  sr.txn_count,
  sr.profit_rank
FROM full_join_cp fjc
CROSS JOIN store_rank sr
ORDER BY sr.profit_rank, fjc.wp_url
LIMIT 100
