WITH filtered_customers AS (
    SELECT c_customer_sk,
           c_email_address,
           regexp_extract(c_email_address, '@([A-Za-z0-9.-]+)$', 1) AS email_domain
    FROM tpcds.customer
    WHERE regexp_like(c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
)
SELECT s.s_store_name,
       SUM(ss.ss_net_profit) AS total_store_profit,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
       COUNT(DISTINCT wp.wp_url) FILTER (WHERE regexp_like(wp.wp_url, '^https?://.*\\.promo.*$')) AS promo_page_visits
FROM filtered_customers fc
JOIN tpcds.store_sales ss
  ON ss.ss_customer_sk = fc.c_customer_sk
JOIN tpcds.store s
  ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN tpcds.web_sales ws
  ON ws.ws_bill_customer_sk = fc.c_customer_sk
LEFT JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE s.s_store_name LIKE '%Market%'
GROUP BY s.s_store_name
ORDER BY total_store_profit DESC
LIMIT 100
