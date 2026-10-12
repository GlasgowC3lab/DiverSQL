WITH store_page_stats AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_closed.d_year AS closed_year,
        d_creation.d_year AS creation_year,
        d_access.d_year AS access_year,
        COUNT(DISTINCT wp.wp_customer_sk) AS unique_customers,
        SUM(wp.wp_char_count) AS total_characters,
        AVG(wp.wp_image_count) AS avg_image_count,
        MAX(wp.wp_max_ad_count) AS max_ad_count,
        MIN(wp.wp_rec_start_date) AS earliest_page_start,
        MAX(wp.wp_rec_end_date) AS latest_page_end
    FROM store s
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_closed.d_date_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE s.s_state = 'CA'
      AND wp.wp_type = 'article'
      AND d_creation.d_year BETWEEN 2015 AND 2020
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d_closed.d_year,
        d_creation.d_year,
        d_access.d_year
    HAVING COUNT(DISTINCT wp.wp_customer_sk) > 5
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    closed_year,
    creation_year,
    access_year,
    unique_customers,
    total_characters,
    avg_image_count,
    max_ad_count,
    earliest_page_start,
    latest_page_end,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_characters DESC) AS rank_by_chars
FROM store_page_stats
ORDER BY total_characters DESC
LIMIT 100
