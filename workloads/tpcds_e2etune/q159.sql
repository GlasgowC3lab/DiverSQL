SELECT c.c_birth_year,
       c.c_preferred_cust_flag,
       COUNT(DISTINCT wp.wp_web_page_sk) AS num_pages,
       SUM(wp.wp_link_count) AS total_links,
       AVG(wp.wp_char_count) AS avg_char_count,
       MAX(wp.wp_image_count) AS max_images,
       RANK() OVER (ORDER BY SUM(wp.wp_link_count) DESC) AS link_rank,
       (SELECT MAX(r_reason_sk) FROM reason) AS max_reason_sk
FROM customer c
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND wp.wp_type IN ('Home', 'Landing')
  AND c.c_birth_year BETWEEN 1970 AND 1990
GROUP BY c.c_birth_year, c.c_preferred_cust_flag
HAVING COUNT(DISTINCT wp.wp_web_page_sk) >= 5
ORDER BY total_links DESC
LIMIT 100
