WITH combined AS (
    SELECT
        wp.wp_web_page_id,
        d.d_date,
        wp.wp_type,
        wp.wp_char_count,
        wp.wp_link_count,
        wp.wp_image_count,
        CASE WHEN d.d_holiday = 'Y' THEN 'Holiday' ELSE 'Non-Holiday' END AS holiday_flag,
        ROW_NUMBER() OVER (PARTITION BY wp.wp_type ORDER BY wp.wp_char_count DESC) AS rn_type_char
    FROM web_page wp
    FULL OUTER JOIN date_dim d
        ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE
        wp.wp_type IN ('home', 'product', 'contact')
        AND wp.wp_char_count BETWEEN 1000 AND 5000
        AND wp.wp_link_count > 5
        AND d.d_moy = 11
        AND d.d_qoy = 2
        AND d.d_following_holiday = 'N'
        AND wp.wp_creation_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2000)

    UNION

    SELECT
        wp.wp_web_page_id,
        d.d_date,
        wp.wp_type,
        wp.wp_char_count,
        wp.wp_link_count,
        wp.wp_image_count,
        CASE WHEN d.d_holiday = 'Y' THEN 'Holiday' ELSE 'Non-Holiday' END AS holiday_flag,
        ROW_NUMBER() OVER (PARTITION BY wp.wp_type ORDER BY wp.wp_char_count DESC) AS rn_type_char
    FROM web_page wp
    FULL OUTER JOIN date_dim d
        ON wp.wp_access_date_sk = d.d_date_sk
    WHERE
        wp.wp_type NOT IN ('login', 'error')
        AND wp.wp_image_count BETWEEN 1 AND 10
        AND wp.wp_max_ad_count IS NOT NULL
        AND d.d_moy = 9
        AND d.d_qoy = 3
        AND d.d_following_holiday = 'Y'
        AND wp.wp_access_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 1999)
)
SELECT
    wp_web_page_id,
    d_date,
    wp_type,
    wp_char_count,
    wp_link_count,
    wp_image_count,
    holiday_flag,
    rn_type_char,
    RANK() OVER (ORDER BY wp_char_count DESC) AS char_count_rank,
    DENSE_RANK() OVER (PARTITION BY holiday_flag ORDER BY wp_char_count DESC) AS holiday_char_rank
FROM combined
WHERE rn_type_char <= 10
ORDER BY char_count_rank
LIMIT 100
