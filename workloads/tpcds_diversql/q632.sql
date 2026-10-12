SELECT
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    COUNT(wp.wp_web_page_sk) AS page_cnt,
    SUM(wp.wp_char_count) AS total_chars
FROM
    customer c
JOIN
    web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE
    c.c_birth_country = 'KOREA'
    AND wp.wp_char_count > 2500
    AND wp.wp_rec_end_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
GROUP BY
    c.c_first_name,
    c.c_last_name,
    c.c_email_address
