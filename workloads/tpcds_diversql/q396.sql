WITH filtered_dates AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_year = 2000
),

combined AS (
    SELECT
        cp.cp_catalog_page_sk AS page_key,
        cp.cp_type AS page_type,
        fd.d_date AS activity_date,
        0 AS link_count,
        cp.cp_start_date_sk AS start_date_sk
    FROM catalog_page cp
    JOIN filtered_dates fd
        ON cp.cp_start_date_sk = fd.d_date_sk
    WHERE cp.cp_department = 'Home'

    UNION ALL

    SELECT
        wp.wp_web_page_sk AS page_key,
        wp.wp_type AS page_type,
        fd.d_date AS activity_date,
        wp.wp_link_count AS link_count,
        wp.wp_creation_date_sk AS start_date_sk
    FROM web_page wp
    JOIN filtered_dates fd
        ON wp.wp_creation_date_sk = fd.d_date_sk
    WHERE wp.wp_autogen_flag = 'N'
      AND wp.wp_link_count > 5
)

SELECT
    c.page_key,
    c.page_type,
    c.activity_date,
    SUM(c.link_count) AS total_link_count,
    (
        SELECT COUNT(*)
        FROM web_page wp_inner
        WHERE wp_inner.wp_creation_date_sk = c.start_date_sk
    ) AS related_web_page_cnt
FROM combined c
GROUP BY
    c.page_key,
    c.page_type,
    c.activity_date,
    c.start_date_sk
HAVING SUM(c.link_count) > 0
ORDER BY c.activity_date DESC, c.page_key
LIMIT 100
