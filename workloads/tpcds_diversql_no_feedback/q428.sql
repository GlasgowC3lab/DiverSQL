WITH filtered AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_last_name,
        c.c_birth_day,
        c.c_email_address,
        c.c_last_review_date,
        wp.wp_web_page_id,
        wp.wp_char_count,
        wp.wp_link_count,
        wp.wp_image_count,
        wp.wp_max_ad_count,
        wp.wp_autogen_flag,
        wp.wp_type
    FROM tpcds.customer c
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_autogen_flag = 'N'
        AND wp.wp_max_ad_count >= 2
        AND c.c_birth_day BETWEEN 10 AND 30
        AND c.c_email_address LIKE '%@%org'
        AND c.c_last_review_date > 2452360
)
SELECT
    f.c_customer_id,
    f.c_last_name,
    COUNT(DISTINCT f.wp_web_page_id) AS page_count,
    SUM(f.wp_char_count) AS total_char_count,
    AVG(f.wp_link_count) AS avg_link_count,
    MIN(f.wp_image_count) AS min_image_count,
    MAX(f.wp_image_count) AS max_image_count
FROM filtered f
GROUP BY f.c_customer_id, f.c_last_name
HAVING COUNT(DISTINCT f.wp_web_page_id) > 1
    AND SUM(f.wp_char_count) > 1000
ORDER BY total_char_count DESC
LIMIT 100
