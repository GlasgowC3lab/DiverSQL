SELECT c.c_customer_id,
       wp.wp_url,
       SUM(cr.cr_return_amount) AS total_return_amount,
       COUNT(ws.ws_order_number) AS order_count,
       wp.wp_type AS page_type,
       (SELECT COUNT(*) FROM web_page) AS total_pages
FROM catalog_returns cr
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE cr.cr_returned_date_sk = 2451019
  AND wp.wp_type = 'order                                             '
GROUP BY c.c_customer_id, wp.wp_url, wp.wp_type
HAVING SUM(cr.cr_return_amount) > 405.60
