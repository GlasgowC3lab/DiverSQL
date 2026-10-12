WITH
  sales_agg AS (
    SELECT
      ws.ws_bill_customer_sk AS cust_sk,
      SUM(ws.ws_net_paid) AS total_sales,
      COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_bill_customer_sk
    HAVING SUM(ws.ws_net_paid) > 500
  ),
  returns_agg AS (
    SELECT
      sr.sr_customer_sk AS cust_sk,
      SUM(sr.sr_return_amt) AS total_returns,
      COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY sr.sr_customer_sk
    HAVING SUM(sr.sr_return_amt) > 200
  ),
  full_customer AS (
    SELECT
      COALESCE(s.cust_sk, r.cust_sk) AS cust_sk,
      s.total_sales,
      s.sales_cnt,
      r.total_returns,
      r.returns_cnt
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r ON s.cust_sk = r.cust_sk
  ),
  filtered AS (
    SELECT
      fc.cust_sk,
      fc.total_sales,
      fc.total_returns,
      CASE
        WHEN fc.total_sales IS NULL THEN 'No Sales'
        WHEN fc.total_returns IS NULL THEN 'No Returns'
        WHEN fc.total_sales > fc.total_returns THEN 'Profit'
        ELSE 'Loss'
      END AS status,
      CONCAT('CUST_', CAST(fc.cust_sk AS varchar)) AS cust_key
    FROM full_customer fc
    JOIN customer c ON fc.cust_sk = c.c_customer_sk
    WHERE (fc.total_sales > 1000 OR fc.total_returns > 500)
      AND regexp_like(CAST(fc.cust_sk AS varchar), '^\\d{7,}$')
      AND EXISTS (
        SELECT 1
        FROM customer_address ca
        WHERE ca.ca_address_sk = c.c_current_addr_sk
          AND ca.ca_county LIKE 'M%'
      )
  )
SELECT cust_key
FROM filtered
INTERSECT
SELECT DISTINCT
  CONCAT('CUST_', CAST(ws.ws_bill_customer_sk AS varchar)) AS cust_key
FROM web_sales ws
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE wp.wp_url LIKE '%/promo/%'
  AND regexp_extract(wp.wp_url, 'promo/([0-9]+)', 1) IS NOT NULL
LIMIT 100
