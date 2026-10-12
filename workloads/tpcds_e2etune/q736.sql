WITH time_stats AS (
  SELECT
    t_shift,
    t_hour,
    COUNT(*) AS time_cnt,
    AVG(t_minute) AS avg_minute
  FROM time_dim
  WHERE t_shift IN ('first', 'second')
    AND t_hour BETWEEN 0 AND 4
  GROUP BY t_shift, t_hour
),
site_agg AS (
  SELECT
    web_market_manager,
    web_state,
    COUNT(*) AS site_cnt,
    SUM(web_tax_percentage) AS total_tax,
    AVG(web_tax_percentage) AS avg_tax
  FROM web_site
  WHERE web_tax_percentage IS NOT NULL
    AND web_state IS NOT NULL
  GROUP BY web_market_manager, web_state
),
site_stats AS (
  SELECT
    web_market_manager,
    web_state,
    site_cnt,
    total_tax,
    avg_tax,
    ROW_NUMBER() OVER (ORDER BY total_tax DESC) AS tax_rank
  FROM site_agg
)
SELECT
  ts.t_shift,
  ts.t_hour,
  ts.time_cnt,
  ts.avg_minute,
  ss.web_market_manager,
  ss.web_state,
  ss.site_cnt,
  ss.total_tax,
  ss.avg_tax,
  ss.tax_rank
FROM time_stats ts
JOIN site_stats ss
  ON ts.t_hour = MOD(LENGTH(ss.web_state), 5)
WHERE ts.t_shift = 'first'
ORDER BY ss.total_tax DESC, ts.t_hour
LIMIT 100
