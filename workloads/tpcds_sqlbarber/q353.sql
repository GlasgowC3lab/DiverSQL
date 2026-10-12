SELECT
  c.c_customer_id,
  d.d_year,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
  (SELECT d2.d_month_seq
   FROM date_dim d2
   WHERE d2.d_date_sk = 2415040
   LIMIT 1) AS reference_month_seq
FROM web_sales ws
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE d.d_year = 1931
  AND wp.wp_type = 'dynamic                                           '
GROUP BY c.c_customer_id, d.d_year
HAVING SUM(ws.ws_ext_sales_price) > 1009.54
