WITH returns_by_month AS (
  SELECT
    dr.d_year,
    dr.d_month_seq,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
  WHERE cr.cr_return_amount > 1000
  GROUP BY dr.d_year, dr.d_month_seq
  HAVING COUNT(*) > 5
),
pages_by_month AS (
  SELECT
    dp.d_year,
    dp.d_month_seq,
    wp.wp_type,
    COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
    SUM(wp.wp_link_count) AS total_links
  FROM web_page wp
  JOIN date_dim dp ON wp.wp_creation_date_sk = dp.d_date_sk
  WHERE wp.wp_type IS NOT NULL
  GROUP BY dp.d_year, dp.d_month_seq, wp.wp_type
)
SELECT
  r.d_year,
  r.d_month_seq,
  p.wp_type,
  r.total_return_amount,
  r.avg_net_loss,
  r.return_cnt,
  p.page_cnt,
  p.total_links,
  r.total_return_amount / NULLIF(p.page_cnt, 0) AS avg_return_per_page
FROM returns_by_month r
JOIN pages_by_month p
  ON r.d_year = p.d_year AND r.d_month_seq = p.d_month_seq
ORDER BY r.total_return_amount DESC
LIMIT 50
