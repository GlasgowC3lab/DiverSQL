SELECT
    ca.ca_state AS state,
    c.c_birth_month AS birth_month,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    AVG(wp.wp_char_count) AS avg_char_count,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_image_count) / NULLIF(COUNT(DISTINCT c.c_customer_sk), 0) AS avg_images_per_customer,
    CASE WHEN SUM(wp.wp_image_count) > 1000 THEN 'Y' ELSE 'N' END AS high_image_volume_flag,
    RANK() OVER (ORDER BY AVG(wp.wp_char_count) DESC) AS state_rank
FROM web_page wp
JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE c.c_last_review_date BETWEEN 2452455 AND 2452588
  AND c.c_birth_month IN (4, 12)
  AND ca.ca_country = 'United States'
GROUP BY ca.ca_state, c.c_birth_month
HAVING COUNT(DISTINCT c.c_customer_sk) >= 5
ORDER BY state_rank
LIMIT 20
