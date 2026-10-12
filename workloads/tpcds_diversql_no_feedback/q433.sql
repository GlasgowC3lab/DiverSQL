WITH addr_parts AS (
       SELECT
         ca_address_sk,
         ca_address_id,
         split(ca_address_id, '-') AS parts
       FROM customer_address
     ),
     addr_unnested AS (
       SELECT
         ca_address_sk,
         part
       FROM addr_parts
       CROSS JOIN UNNEST(parts) AS t(part)
     )
SELECT
  d.d_year,
  regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
  sm.sm_carrier,
  COUNT(DISTINCT ws.ws_order_number)               AS orders,
  SUM(ws.ws_net_paid)                             AS total_net_paid,
  COUNT(DISTINCT part)                            AS distinct_address_parts
FROM web_sales ws
JOIN date_dim d       ON ws.ws_sold_date_sk = d.d_date_sk
JOIN customer c        ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN ship_mode sm     ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN addr_unnested au ON ca.ca_address_sk = au.ca_address_sk
WHERE d.d_year = 2001
  AND sm.sm_carrier LIKE 'Fed%'
  AND regexp_like(ca.ca_zip, '^9[0-9]{4}$')
  AND regexp_like(ca.ca_street_number, '^[4-5][0-9]{2}$')
  AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_order_number = ws.ws_order_number
      )
GROUP BY d.d_year,
         regexp_extract(c.c_email_address, '@(.+)$', 1),
         sm.sm_carrier
ORDER BY total_net_paid DESC
LIMIT 100
