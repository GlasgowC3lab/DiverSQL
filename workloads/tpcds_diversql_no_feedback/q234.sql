WITH combined_sales AS (
  SELECT
    ca.ca_state AS state,
    p.p_promo_name AS promo_name,
    cs.cs_net_paid AS net_paid,
    c.c_email_address AS email_address
  FROM
    catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE
    regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
    AND p.p_promo_name LIKE '%Clearance%'
  UNION ALL
  SELECT
    ca.ca_state AS state,
    p.p_promo_name AS promo_name,
    ws.ws_net_paid AS net_paid,
    c.c_email_address AS email_address
  FROM
    web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE
    regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
    AND p.p_promo_name LIKE '%Clearance%'
)
SELECT
  state,
  promo_name,
  SUM(net_paid) AS total_net_paid,
  COUNT(*) AS transaction_count,
  CONCAT(state, '-', SUBSTRING(promo_name, 1, 10)) AS state_promo_key,
  regexp_extract(MAX(email_address), '@(.+)$', 1) AS sample_email_domain
FROM combined_sales
GROUP BY ROLLUP(state, promo_name)
ORDER BY state, promo_name
