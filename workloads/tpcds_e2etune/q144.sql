SELECT
    cc.cc_state,
    wp.wp_type,
    COUNT(*) AS row_cnt,
    SUM(cc.cc_sq_ft) AS total_sq_ft,
    AVG(cc.cc_tax_percentage) AS avg_tax_pct,
    SUM(wp.wp_char_count) AS total_char_cnt,
    AVG(wp.wp_image_count) AS avg_image_cnt
FROM call_center cc
CROSS JOIN web_page wp
WHERE cc.cc_manager = 'Bob Belcher'
  AND cc.cc_country = 'United States'
  AND cc.cc_rec_start_date >= DATE '2020-01-01'
  AND wp.wp_char_count BETWEEN 500 AND 5000
  AND wp.wp_type <> ''
GROUP BY cc.cc_state, wp.wp_type
HAVING COUNT(*) > 10
ORDER BY row_cnt DESC
LIMIT 100
