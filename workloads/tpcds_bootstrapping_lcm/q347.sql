SELECT
  d.d_year,
  d.d_quarter_name,
  s.s_state,
  ws.web_state,
  wp.wp_type,
  COUNT(DISTINCT s.s_store_sk) AS store_cnt,
  COUNT(DISTINCT ws.web_site_sk) AS site_cnt,
  COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
  SUM(CASE WHEN ws.web_gmt_offset > 0 THEN 1 ELSE 0 END) AS pos_gmt_offset_sites,
  AVG(CAST(s.s_tax_percentage AS double)) AS avg_store_tax,
  MAX(d.d_date) AS latest_date
FROM date_dim d
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
     AND ws.web_close_date_sk = d.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d.d_date_sk
     AND wp.wp_access_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND ws.web_state = 'CA'
GROUP BY ROLLUP (d.d_year, d.d_quarter_name, s.s_state, ws.web_state, wp.wp_type)
HAVING COUNT(*) > 5
ORDER BY d.d_year, d.d_quarter_name
LIMIT 100
