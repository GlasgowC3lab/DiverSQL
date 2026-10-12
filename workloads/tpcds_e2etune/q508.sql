WITH page_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_country AS birth_country,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        SUM(wp.wp_link_count) AS total_links,
        AVG(wp.wp_image_count) AS avg_images,
        COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
        MAX(wp.wp_rec_start_date) AS latest_page_start
    FROM web_page wp
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_country IN ('IRELAND', 'CYPRUS')
      AND wp.wp_type = 'article'
      AND wp.wp_rec_start_date >= DATE '2022-01-01'
    GROUP BY
        c.c_customer_sk,
        c.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status
),

demographic_agg AS (
    SELECT
        birth_country,
        gender,
        marital_status,
        COUNT(*) AS num_customers,
        SUM(total_links) AS total_links_all,
        AVG(avg_images) AS avg_images_per_customer,
        SUM(page_cnt) AS total_pages,
        MAX(latest_page_start) AS most_recent_page_start
    FROM page_stats
    GROUP BY
        birth_country,
        gender,
        marital_status
    HAVING COUNT(*) >= 5
)
SELECT
    birth_country,
    gender,
    marital_status,
    num_customers,
    total_links_all,
    avg_images_per_customer,
    total_pages,
    most_recent_page_start,
    ROW_NUMBER() OVER (PARTITION BY birth_country ORDER BY total_links_all DESC) AS rank_by_links
FROM demographic_agg
ORDER BY total_links_all DESC
LIMIT 50
