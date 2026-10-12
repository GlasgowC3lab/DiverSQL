WITH intersect_customers AS (
  SELECT ss_customer_sk AS customer_sk FROM store_sales
  INTERSECT
  SELECT ws_bill_customer_sk FROM web_sales
),

store_agg AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    p.p_promo_name,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_store_customers,
    SUM(ss.ss_ext_sales_price) AS store_sales_amount,
    CASE
      WHEN SUM(ss.ss_ext_discount_amt) > 10000 THEN 'High Discount'
      ELSE 'Low Discount'
    END AS discount_category
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE ss.ss_customer_sk IN (SELECT customer_sk FROM intersect_customers)
    AND ss.ss_customer_sk IN (
      SELECT c.c_customer_sk
      FROM customer c
      WHERE regexp_like(c.c_email_address, '^.*@example\\.com$')
    )
    AND regexp_like(s.s_store_name, '^A.*')
  GROUP BY s.s_store_id, s.s_store_name, p.p_promo_name
),

web_agg AS (
  SELECT
    wp.wp_web_page_id,
    p.p_promo_name,
    COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_web_customers,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    CASE
      WHEN SUM(ws.ws_ext_discount_amt) > 8000 THEN 'High Discount'
      ELSE 'Low Discount'
    END AS discount_category
  FROM web_sales ws
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE ws.ws_bill_customer_sk IN (SELECT customer_sk FROM intersect_customers)
    AND wp.wp_url LIKE '%/promo%'
  GROUP BY wp.wp_web_page_id, p.p_promo_name
)

SELECT
  COALESCE(sa.s_store_id, 'N/A')                               AS store_id,
  COALESCE(sa.s_store_name, 'N/A')                             AS store_name,
  COALESCE(sa.p_promo_name, wa.p_promo_name)                  AS promo_name,
  COALESCE(sa.distinct_store_customers, 0)                    AS distinct_store_customers,
  COALESCE(wa.distinct_web_customers, 0)                      AS distinct_web_customers,
  COALESCE(sa.store_sales_amount, 0) + COALESCE(wa.web_sales_amount, 0) AS total_sales_amount,
  CASE
    WHEN COALESCE(sa.discount_category, wa.discount_category) = 'High Discount' THEN 'High'
    ELSE 'Low'
  END                                                          AS overall_discount_category,
  CONCAT(COALESCE(sa.s_store_name, ''), ' - ', COALESCE(wa.p_promo_name, '')) AS store_promo_label,
  regexp_extract(regexp_replace(COALESCE(sa.s_store_name, ''), '\\s+', ''), '(.*)', 1) AS cleaned_store_name
FROM store_agg sa
FULL OUTER JOIN web_agg wa
  ON sa.p_promo_name = wa.p_promo_name
ORDER BY total_sales_amount DESC
LIMIT 100
