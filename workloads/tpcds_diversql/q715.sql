WITH intersect_stores AS (
   SELECT s.s_store_sk
   FROM store s
   WHERE s.s_market_id IN (1, 7)
   INTERSECT
   SELECT sr.sr_store_sk
   FROM store_returns sr
   WHERE sr.sr_return_quantity > 0
),
joined_data AS (
   SELECT
       cp.cp_department,
       cp.cp_catalog_page_number,
       w.w_city,
       r.r_reason_desc,
       s.s_store_name,
       cr.cr_return_amount,
       cr.cr_return_tax,
       cr.cr_return_quantity,
       CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS amount_category,
       ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY cr.cr_return_amount DESC) AS dept_rank
   FROM catalog_returns cr
   JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN store_returns sr ON sr.sr_reason_sk = r.r_reason_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   WHERE cp.cp_catalog_page_number = 13
     AND w.w_suite_number = 'Suite 350'
     AND s.s_division_id = 1
     AND s.s_gmt_offset = -5.00
     AND r.r_reason_desc LIKE '%customer%'
     AND s.s_store_sk IN (SELECT s_store_sk FROM intersect_stores)
     AND cr.cr_return_amount IS NOT NULL
)
SELECT
    cp_department,
    amount_category,
    COUNT(*) AS return_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_tax) AS avg_return_tax,
    MIN(cr_return_quantity) AS min_quantity,
    MAX(cr_return_quantity) AS max_quantity,
    SUM(CASE WHEN amount_category = 'High' THEN cr_return_amount ELSE 0 END) AS high_return_sum
FROM joined_data
WHERE dept_rank <= 3
GROUP BY cp_department, amount_category
ORDER BY total_return_amount DESC
LIMIT 100
