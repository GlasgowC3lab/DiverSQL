WITH filtered_customers AS (
    SELECT
        c_customer_sk,
        c_birth_month,
        c_birth_country
    FROM customer
    WHERE c_birth_country IN ('CHILE', 'MEXICO')
),
page_aggregates AS (
    SELECT
        wp.wp_type,
        c.c_birth_month,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
        SUM(wp.wp_link_count) AS total_links,
        AVG(wp.wp_char_count) AS avg_char_count,
        MAX(wp.wp_image_count) AS max_image_count
    FROM web_page wp
    JOIN filtered_customers c
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE wp.wp_type IN ('product', 'category')
    GROUP BY wp.wp_type, c.c_birth_month
)
SELECT
    pa.wp_type,
    pa.c_birth_month,
    pa.distinct_customers,
    pa.total_links,
    pa.avg_char_count,
    pa.max_image_count,
    RANK() OVER (ORDER BY pa.total_links DESC) AS link_rank,
    (SELECT r_reason_desc FROM reason WHERE r_reason_id = 'R001') AS example_reason
FROM page_aggregates pa
ORDER BY pa.total_links DESC
LIMIT 20
