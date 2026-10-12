WITH agg AS (
    SELECT
        c.c_birth_month,
        c.c_salutation,
        COUNT(DISTINCT wp.wp_web_page_id) AS num_pages,
        SUM(wp.wp_char_count) AS total_chars,
        AVG(wp.wp_image_count) AS avg_images,
        COUNT(*) AS total_rows
    FROM
        customer c
    JOIN
        web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_month IN (4, 7, 10)
        AND wp.wp_type = 'Landing'
        AND wp.wp_rec_end_date >= DATE '2023-01-01'
    GROUP BY
        c.c_birth_month,
        c.c_salutation
    HAVING
        COUNT(*) > 10
)
SELECT
    c_birth_month,
    c_salutation,
    num_pages,
    total_chars,
    avg_images,
    RANK() OVER (PARTITION BY c_birth_month ORDER BY total_chars DESC) AS month_rank
FROM agg
ORDER BY c_birth_month, month_rank
LIMIT 100
