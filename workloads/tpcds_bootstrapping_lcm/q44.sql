WITH store_page_stats AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_store.d_year AS store_closed_year,
        d_store.d_month_seq AS store_closed_month_seq,
        d_create.d_year AS page_creation_year,
        d_create.d_month_seq AS page_creation_month_seq,
        d_access.d_year AS page_access_year,
        d_access.d_month_seq AS page_access_month_seq,
        COUNT(DISTINCT wp.wp_web_page_id) AS num_pages,
        SUM(wp.wp_image_count) AS total_images,
        AVG(wp.wp_char_count) AS avg_char_count,
        SUM(CASE WHEN d_access.d_weekend = 'Y' THEN 1 ELSE 0 END) AS access_weekend_pages
    FROM store s
    JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
    JOIN web_page wp ON wp.wp_creation_date_sk = d_store.d_date_sk
    JOIN date_dim d_create ON wp.wp_creation_date_sk = d_create.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE s.s_state = 'CA'
      AND d_store.d_year >= 2015
      AND wp.wp_type = 'Landing'
      AND s.s_number_employees > 10
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_store.d_year,
        d_store.d_month_seq,
        d_create.d_year,
        d_create.d_month_seq,
        d_access.d_year,
        d_access.d_month_seq
)
SELECT
    sp.s_store_id,
    sp.s_store_name,
    sp.s_city,
    sp.store_closed_year,
    sp.store_closed_month_seq,
    sp.page_creation_year,
    sp.page_creation_month_seq,
    sp.page_access_year,
    sp.page_access_month_seq,
    sp.num_pages,
    sp.total_images,
    sp.avg_char_count,
    sp.access_weekend_pages,
    ROW_NUMBER() OVER (PARTITION BY sp.store_closed_year ORDER BY sp.total_images DESC) AS rank_within_year
FROM store_page_stats sp
ORDER BY sp.total_images DESC, sp.s_store_id
LIMIT 50
