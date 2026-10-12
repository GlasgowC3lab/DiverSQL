SELECT wp.wp_url,
       wp.wp_type,
       d.d_date AS creation_date,
       SUM(wp.wp_link_count) AS total_links
FROM web_page wp
INNER JOIN date_dim d
  ON wp.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND wp.wp_max_ad_count >= 2
GROUP BY wp.wp_url, wp.wp_type, d.d_date
