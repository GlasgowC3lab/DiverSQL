WITH wp_per_customer AS (
    SELECT
        wp.wp_customer_sk,
        COUNT(*) AS page_count,
        AVG(wp.wp_image_count) AS avg_images,
        SUM(wp.wp_char_count) AS total_chars,
        MAX(wp.wp_access_date_sk) AS last_access_sk
    FROM web_page wp
    WHERE wp.wp_type = 'monthly'
      AND wp.wp_creation_date_sk BETWEEN 2450815 AND 2451088
    GROUP BY wp.wp_customer_sk
),
cust_details AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_country,
        c.c_preferred_cust_flag
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
),
agg AS (
    SELECT
        cd.c_birth_country,
        cd.c_preferred_cust_flag,
        COUNT(*) AS num_customers,
        SUM(wpc.page_count) AS total_pages,
        AVG(wpc.avg_images) AS avg_images_per_page,
        SUM(wpc.total_chars) AS total_characters
    FROM cust_details cd
    JOIN wp_per_customer wpc
        ON cd.c_customer_sk = wpc.wp_customer_sk
    GROUP BY cd.c_birth_country, cd.c_preferred_cust_flag
    HAVING SUM(wpc.page_count) > 10
)
SELECT
    agg.c_birth_country,
    agg.c_preferred_cust_flag,
    agg.num_customers,
    agg.total_pages,
    agg.avg_images_per_page,
    agg.total_characters,
    PERCENT_RANK() OVER (ORDER BY agg.total_pages DESC) AS page_count_pct_rank,
    (SELECT COUNT(*) FROM item i WHERE i.i_category = 'Electronics') AS total_electronics_items,
    (SELECT COUNT(*) FROM catalog_page cp WHERE cp.cp_type = 'monthly' AND cp.cp_start_date_sk BETWEEN 2450815 AND 2451088) AS total_monthly_catalog_pages
FROM agg
ORDER BY agg.total_pages DESC
LIMIT 50
