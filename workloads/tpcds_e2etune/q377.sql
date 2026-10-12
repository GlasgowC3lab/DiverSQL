WITH page_stats AS (
    SELECT
        wp.wp_customer_sk,
        COUNT(*) AS page_cnt,
        SUM(wp.wp_char_count) AS total_chars,
        AVG(wp.wp_char_count) AS avg_chars,
        SUM(CASE WHEN wp.wp_image_count > 0 THEN 1 ELSE 0 END) AS pages_with_images,
        MAX(wp.wp_rec_start_date) AS latest_page_date
    FROM web_page wp
    WHERE wp.wp_rec_start_date >= DATE '2022-01-01'
      AND wp.wp_image_count >= 3
    GROUP BY wp.wp_customer_sk
    HAVING COUNT(*) >= 5
)
SELECT
    c.c_customer_id,
    c.c_email_address,
    c.c_birth_year,
    c.c_preferred_cust_flag,
    ps.page_cnt,
    ps.total_chars,
    ps.avg_chars,
    ps.pages_with_images,
    RANK() OVER (ORDER BY ps.total_chars DESC) AS char_rank
FROM customer c
JOIN page_stats ps
  ON c.c_customer_sk = ps.wp_customer_sk
WHERE c.c_birth_year BETWEEN 1970 AND 1990
  AND c.c_preferred_cust_flag = 'Y'
ORDER BY char_rank
LIMIT 10
