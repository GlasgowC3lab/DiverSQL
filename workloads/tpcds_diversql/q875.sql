SELECT
    c.c_customer_id,
    COUNT(*) AS page_count,
    MIN(wp.wp_rec_start_date) AS first_page_date,
    MAX(wp.wp_rec_start_date) AS last_page_date
FROM
    tpcds.customer c
JOIN
    tpcds.web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
WHERE
    c.c_current_cdemo_sk = 1114415
    AND wp.wp_max_ad_count > 0
GROUP BY
    c.c_customer_id
HAVING
    COUNT(*) >= 2
ORDER BY
    page_count DESC
LIMIT 50
