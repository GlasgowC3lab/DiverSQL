WITH page_site_agg AS (
  SELECT
    s.web_site_id,
    s.web_name,
    p.wp_type,
    COUNT(DISTINCT p.wp_web_page_id) AS distinct_pages,
    SUM(p.wp_image_count) AS sum_images,
    AVG(p.wp_char_count) AS avg_char_count,
    SUM(p.wp_link_count) AS sum_links,
    SUM(p.wp_max_ad_count) AS sum_ad_counts,
    MIN(p.wp_rec_start_date) AS min_page_start_date,
    MAX(p.wp_rec_end_date) AS max_page_end_date
  FROM web_page p
  JOIN web_site s
    ON p.wp_customer_sk = s.web_company_id
  WHERE p.wp_type IN ('ad', 'welcome', 'general')
    AND p.wp_max_ad_count > 0
    AND s.web_state = 'CA'
    AND s.web_rec_start_date >= DATE '2000-01-01'
    AND s.web_rec_end_date <= DATE '2025-12-31'
  GROUP BY s.web_site_id, s.web_name, p.wp_type
  HAVING COUNT(DISTINCT p.wp_web_page_id) >= 5
)
SELECT
  web_site_id,
  web_name,
  wp_type,
  distinct_pages,
  sum_images,
  avg_char_count,
  sum_links,
  sum_ad_counts,
  (sum_images * 1.0 / NULLIF(distinct_pages,0)) AS avg_images_per_page,
  ROW_NUMBER() OVER (PARTITION BY web_site_id ORDER BY sum_images DESC) AS type_rank_by_images
FROM page_site_agg
ORDER BY sum_images DESC, avg_char_count DESC
LIMIT 100
