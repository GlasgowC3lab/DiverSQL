WITH page_filtered AS (
    SELECT cp_catalog_page_sk,
           cp_department,
           cp_catalog_page_number,
           cp_description
    FROM catalog_page
    WHERE cp_department = 'DEPARTMENT'
      AND cp_catalog_page_number BETWEEN 10 AND 20
)
SELECT
    cr.cr_returned_date_sk,
    cr.cr_returned_time_sk,
    t.t_hour,
    t.t_sub_shift,
    p.cp_catalog_page_number,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_catalog_page_sk = cr.cr_catalog_page_sk
    ) AS total_return_amount_by_page,
    RANK() OVER (PARTITION BY p.cp_department ORDER BY cr.cr_return_amount DESC) AS dept_return_amount_rank,
    ROW_NUMBER() OVER (PARTITION BY t.t_hour ORDER BY cr.cr_return_amount DESC) AS hour_return_seq
FROM catalog_returns cr
JOIN page_filtered p
    ON cr.cr_catalog_page_sk = p.cp_catalog_page_sk
JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
WHERE t.t_hour IN (1, 7, 19)                     -- filter on specific hours
  AND t.t_sub_shift = 'morning'                 -- filter on sub‑shift
  AND cr.cr_return_amount > 50.00               -- filter on amount
  AND EXISTS (
        SELECT 1
        FROM catalog_page cp2
        WHERE cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
          AND cp2.cp_description LIKE '%special%'
    )                                           -- existence filter
ORDER BY cr.cr_returned_date_sk DESC, dept_return_amount_rank
OFFSET 0 LIMIT 100
