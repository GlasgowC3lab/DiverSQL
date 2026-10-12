SELECT
  ca.ca_country,
  r.r_reason_desc,
  DATE_FORMAT(CAST(t.t_time_id AS DATE), '%Y-%m') AS month,
  COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
  SUM(wp.wp_char_count) AS total_chars,
  AVG(wp.wp_link_count) AS avg_links
FROM customer_address ca
JOIN web_page wp ON TRUE
JOIN time_dim t ON wp.wp_creation_date_sk = t.t_time_sk
JOIN reason r ON wp.wp_type = r.r_reason_desc
WHERE ca.ca_gmt_offset = -5.00
  AND t.t_hour BETWEEN 8 AND 18
  AND wp.wp_autogen_flag = 'N'
GROUP BY
  ca.ca_country,
  r.r_reason_desc,
  DATE_FORMAT(CAST(t.t_time_id AS DATE), '%Y-%m')
HAVING COUNT(DISTINCT wp.wp_web_page_sk) > 10
ORDER BY page_cnt DESC
LIMIT 100
