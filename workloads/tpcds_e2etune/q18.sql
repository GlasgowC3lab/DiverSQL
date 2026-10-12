SELECT ib.ib_income_band_sk,
       COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
       SUM(wp.wp_char_count) AS total_chars,
       AVG(wp.wp_link_count) AS avg_links,
       MAX(wp.wp_image_count) AS max_images,
       MIN(wp.wp_rec_end_date) AS earliest_rec_end_date
FROM income_band ib
JOIN web_page wp
  ON wp.wp_customer_sk BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
WHERE wp.wp_rec_end_date >= DATE '1999-01-01'
  AND wp.wp_type = 'Content'
GROUP BY ib.ib_income_band_sk
HAVING COUNT(*) > 5
ORDER BY total_chars DESC
LIMIT 50
