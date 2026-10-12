WITH store_rev AS (
   SELECT ca.ca_state AS state,
          SUM(ss.ss_ext_sales_price) AS total_sales
   FROM store_sales ss
   JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   WHERE ss.ss_ext_sales_price > 100
     AND p.p_purpose = 'Unknown'
   GROUP BY ca.ca_state
),
web_rev AS (
   SELECT ca.ca_state AS state,
          SUM(ws.ws_ext_sales_price) AS total_sales
   FROM web_sales ws
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
   WHERE ws.ws_ext_sales_price > 100
   GROUP BY ca.ca_state
)
SELECT state, total_sales
FROM store_rev
UNION
SELECT state, total_sales
FROM web_rev
ORDER BY total_sales DESC
LIMIT 100
