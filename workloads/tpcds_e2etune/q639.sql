WITH category_month_returns AS (
  SELECT
    i.i_category AS category,
    d.d_year,
    d.d_month_seq,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages_accessed
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN item i ON cr.cr_item_sk = i.i_item_sk
  LEFT JOIN web_page wp ON wp.wp_access_date_sk = d.d_date_sk
  WHERE cr.cr_return_quantity > 10
    AND cr.cr_reason_sk IN (16, 17, 59)
    AND d.d_year = 2001
  GROUP BY i.i_category, d.d_year, d.d_month_seq
  HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT
  category,
  d_year,
  d_month_seq,
  num_returns,
  total_return_amount,
  avg_return_tax,
  distinct_pages_accessed,
  RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_return_amount DESC) AS category_rank
FROM category_month_returns
ORDER BY d_year, d_month_seq, total_return_amount DESC
LIMIT 100
