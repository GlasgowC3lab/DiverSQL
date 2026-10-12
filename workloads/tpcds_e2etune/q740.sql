WITH store_agg AS (
  SELECT
    s_market_id,
    s_market_desc,
    COUNT(*) AS store_cnt,
    SUM(s_floor_space) AS total_floor_space,
    AVG(s_gmt_offset) AS avg_gmt_offset,
    MIN(s_rec_start_date) AS earliest_open,
    MAX(s_rec_end_date) AS latest_close,
    COUNT(DISTINCT s_manager) AS distinct_managers
  FROM store
  WHERE s_manager IN ('William Ward', 'Scott Smith', 'David Thomas')
    AND s_floor_space > 5000000
  GROUP BY s_market_id, s_market_desc
),
web_agg AS (
  SELECT
    web_mkt_id,
    COUNT(*) AS site_cnt,
    AVG(web_tax_percentage) AS avg_tax_pct,
    AVG(web_gmt_offset) AS avg_web_gmt_offset,
    MAX(web_name) AS representative_site_name
  FROM web_site
  WHERE web_state = 'CA'
    AND web_tax_percentage > 5.00
  GROUP BY web_mkt_id
),
time_filter AS (
  SELECT
    MAX(t_hour) AS max_hour,
    MIN(t_hour) AS min_hour
  FROM time_dim
  WHERE t_shift = 'Evening'
)
SELECT
  s.s_market_desc AS market,
  s.store_cnt,
  s.total_floor_space,
  s.avg_gmt_offset,
  w.site_cnt,
  w.avg_tax_pct,
  w.avg_web_gmt_offset,
  tf.max_hour,
  tf.min_hour,
  ROW_NUMBER() OVER (ORDER BY s.total_floor_space DESC) AS market_rank
FROM store_agg s
JOIN web_agg w
  ON s.s_market_id = w.web_mkt_id
CROSS JOIN time_filter tf
WHERE s.avg_gmt_offset > -7.00
ORDER BY s.total_floor_space DESC
LIMIT 20
