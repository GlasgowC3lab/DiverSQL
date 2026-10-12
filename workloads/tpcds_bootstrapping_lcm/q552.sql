SELECT
    cc.cc_state,
    cc.cc_city,
    d_closed.d_year     AS closed_year,
    d_open.d_year       AS open_year,
    d_access.d_quarter_name AS access_quarter,
    s.s_state,
    s.s_city,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    COUNT(*)                              AS total_rows,
    SUM(s.s_floor_space)                  AS total_floor_space,
    AVG(cc.cc_tax_percentage)             AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage)               AS avg_store_tax_pct,
    SUM(CASE WHEN wp.wp_type = 'index'   THEN wp.wp_image_count ELSE 0 END) AS index_image_count,
    SUM(CASE WHEN wp.wp_type = 'content' THEN wp.wp_link_count  ELSE 0 END) AS content_link_count,
    (d_closed.d_year - d_open.d_year)    AS years_between_open_and_close,
    ROUND(AVG(cc.cc_tax_percentage) * 100, 2) AS avg_cc_tax_percent_int
FROM call_center cc
JOIN date_dim d_closed ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open   ON cc.cc_open_date_sk   = d_open.d_date_sk
JOIN store s           ON s.s_closed_date_sk   = d_closed.d_date_sk
JOIN web_page wp       ON wp.wp_creation_date_sk = d_closed.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_closed.d_year BETWEEN 1995 AND 2025
  AND s.s_floor_space IS NOT NULL
GROUP BY
    cc.cc_state,
    cc.cc_city,
    d_closed.d_year,
    d_open.d_year,
    d_access.d_quarter_name,
    s.s_state,
    s.s_city
HAVING COUNT(DISTINCT wp.wp_web_page_sk) > 10
ORDER BY total_floor_space DESC
LIMIT 100
