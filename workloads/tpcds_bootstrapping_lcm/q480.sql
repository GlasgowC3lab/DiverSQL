SELECT
    cc.cc_company_name,
    cc.cc_manager,
    s.s_store_name,
    s.s_floor_space,
    cd_closed.d_year AS closed_year,
    cd_open.d_year AS open_year,
    cd_closed.d_quarter_name AS closed_quarter,
    cd_open.d_quarter_name AS open_quarter,
    COUNT(DISTINCT wp.wp_web_page_id) AS web_pages_created_on_closed_date,
    SUM(wp.wp_image_count) AS total_image_count,
    AVG(wp.wp_char_count) AS avg_char_count,
    MAX(wp.wp_access_date_sk) - MIN(wp.wp_creation_date_sk) AS max_access_creation_sk_diff,
    cd_access.d_day_name AS access_day_name,
    cd_access.d_weekend AS access_is_weekend,
    DATE_DIFF('day', cd_open.d_date, cd_closed.d_date) AS days_between_open_and_closed
FROM call_center cc
JOIN date_dim cd_closed
    ON cc.cc_closed_date_sk = cd_closed.d_date_sk
JOIN date_dim cd_open
    ON cc.cc_open_date_sk = cd_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = cd_closed.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = cd_closed.d_date_sk
JOIN date_dim cd_access
    ON wp.wp_access_date_sk = cd_access.d_date_sk
WHERE cd_closed.d_year BETWEEN 2015 AND 2020
  AND s.s_floor_space > 1000
  AND wp.wp_autogen_flag = 'N'
GROUP BY
    cc.cc_company_name,
    cc.cc_manager,
    s.s_store_name,
    s.s_floor_space,
    cd_closed.d_year,
    cd_open.d_year,
    cd_closed.d_quarter_name,
    cd_open.d_quarter_name,
    cd_access.d_day_name,
    cd_access.d_weekend,
    DATE_DIFF('day', cd_open.d_date, cd_closed.d_date)
ORDER BY total_image_count DESC
LIMIT 100
