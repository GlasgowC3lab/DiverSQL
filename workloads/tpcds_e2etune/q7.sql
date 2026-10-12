SELECT
    ca.ca_state AS state,
    COUNT(*) AS total_page_visits,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    AVG(wp.wp_char_count) AS avg_char_count
FROM web_page wp
JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE wp.wp_type = 'Content'
  AND wp.wp_rec_start_date >= DATE '2023-01-01'
  AND cd.cd_gender = 'F'
  AND cd.cd_marital_status = 'M'
  AND hd.hd_buy_potential = 'HIGH'
GROUP BY ca.ca_state
HAVING COUNT(*) >= 100
ORDER BY total_page_visits DESC
LIMIT 10
