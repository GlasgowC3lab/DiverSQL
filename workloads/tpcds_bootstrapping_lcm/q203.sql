SELECT
    d_start.d_quarter_seq AS quarter_seq,
    s.s_state AS store_state,
    d_access.d_month_seq AS access_month_seq,
    COUNT(DISTINCT p.p_promo_id) AS promo_count,
    SUM(p.p_cost) AS total_promo_cost,
    AVG(s.s_floor_space) AS avg_floor_space,
    SUM(wp.wp_image_count) AS total_image_count,
    SUM(wp.wp_link_count) AS total_link_count,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages,
    SUM(CASE WHEN p.p_channel_tv IS NOT NULL THEN p.p_cost ELSE 0 END) AS tv_promo_cost,
    SUM(CASE WHEN p.p_channel_email IS NOT NULL THEN p.p_cost ELSE 0 END) AS email_promo_cost
FROM promotion p
JOIN date_dim d_start
  ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
  ON p.p_end_date_sk = d_end.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d_start.d_date_sk
JOIN date_dim d_access
  ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE d_start.d_year = 2022
  AND s.s_state IS NOT NULL
GROUP BY GROUPING SETS (
    (d_start.d_quarter_seq, s.s_state, d_access.d_month_seq),
    (d_start.d_quarter_seq, s.s_state),
    (d_start.d_quarter_seq),
    (s.s_state)
)
HAVING SUM(p.p_cost) > 5000
ORDER BY total_promo_cost DESC
LIMIT 100
