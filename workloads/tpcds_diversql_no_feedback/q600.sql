WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
) 
SELECT
    cp.cp_department                     AS department,
    td.t_meal_time                       AS meal_time,
    COUNT(*)                             AS returns_cnt,
    SUM(sr.cr_return_amount)            AS total_return_amount,
    AVG(sr.cr_return_amount)            AS avg_return_amount,
    regexp_extract(cp.cp_catalog_page_id, '(\\d+)', 1) AS catalog_page_number_extracted,
    CONCAT(cp.cp_department, '-', cp.cp_type)       AS dept_type_concat
FROM sampled_returns sr
JOIN catalog_page cp
      ON sr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim td
      ON sr.cr_returned_time_sk = td.t_time_sk
JOIN reason r
      ON sr.cr_reason_sk = r.r_reason_sk
JOIN household_demographics hd
      ON sr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE cp.cp_description LIKE '%summer%'
  AND regexp_like(cp.cp_type, '^A')
  AND r.r_reason_desc LIKE '%defect%'
  AND hd.hd_buy_potential = '1001-5000'
GROUP BY
    cp.cp_department,
    td.t_meal_time,
    regexp_extract(cp.cp_catalog_page_id, '(\\d+)', 1),
    CONCAT(cp.cp_department, '-', cp.cp_type)
ORDER BY total_return_amount DESC
LIMIT 100
