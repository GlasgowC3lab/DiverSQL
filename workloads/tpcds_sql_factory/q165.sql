WITH page_stats AS (
  SELECT
    cp.cp_catalog_page_sk,
    cp.cp_department,
    cp.cp_catalog_page_number,
    cp.cp_type,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cr.cr_warehouse_sk) AS warehouse_cnt,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(ca.ca_city) AS example_returning_city,
    MIN(w.w_city) AS example_warehouse_city
  FROM catalog_returns cr
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer_address ca ON cr.cr_returning_addr_sk = ca.ca_address_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  GROUP BY cp.cp_catalog_page_sk, cp.cp_department, cp.cp_catalog_page_number, cp.cp_type
),
ranked_pages AS (
  SELECT
    ps.*, 
    ROW_NUMBER() OVER (PARTITION BY ps.cp_department ORDER BY ps.avg_return_amount DESC) AS dept_page_rank,
    LAG(ps.avg_return_amount) OVER (PARTITION BY ps.cp_department ORDER BY ps.avg_return_amount DESC) AS prev_avg_return_amount
  FROM page_stats ps
)
SELECT
  rp.cp_department,
  rp.cp_catalog_page_number,
  rp.cp_type,
  rp.total_return_amount,
  rp.warehouse_cnt,
  rp.avg_return_amount,
  rp.dept_page_rank,
  CASE
    WHEN rp.prev_avg_return_amount IS NULL THEN 'N/A'
    ELSE CAST(rp.prev_avg_return_amount AS VARCHAR)
  END AS previous_avg_return_amount,
  rp.example_returning_city,
  rp.example_warehouse_city
FROM ranked_pages rp
WHERE rp.dept_page_rank <= 5
ORDER BY rp.cp_department, rp.dept_page_rank
