SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  w.wp_url,
  w.wp_image_count
FROM tpcds.customer AS c
JOIN tpcds.web_page AS w
  ON w.wp_customer_sk = c.c_customer_sk
WHERE c.c_salutation = 'Mr.'
  AND w.wp_image_count = 3
ORDER BY c.c_customer_id
LIMIT 100
