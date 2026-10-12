WITH filtered AS ( 
    SELECT 
        cp.cp_department,
        cp.cp_catalog_number,
        d.d_year,
        d.d_month_seq,
        cp.cp_catalog_page_id,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        REGEXP_EXTRACT(cp.cp_catalog_page_id, '(\\d+)$') AS page_id_num
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE REGEXP_LIKE(cp.cp_description, '(?i)edit')
      AND cp.cp_type LIKE 'catalog%'
),
aggregated AS ( 
    SELECT 
        d_year,
        d_month_seq,
        cp_department,
        cp_catalog_number,
        CONCAT(cp_department, '-', CAST(cp_catalog_number AS varchar)) AS dept_page,
        page_id_num,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_qty
    FROM filtered
    GROUP BY 
        d_year,
        d_month_seq,
        cp_department,
        cp_catalog_number,
        page_id_num
)
SELECT 
    a.d_year,
    a.d_month_seq,
    a.cp_department,
    a.cp_catalog_number,
    a.dept_page,
    a.page_id_num,
    a.total_return_amount,
    a.total_return_qty
FROM (
    SELECT 
        ag.*,
        ROW_NUMBER() OVER (PARTITION BY ag.d_year, ag.d_month_seq ORDER BY ag.total_return_amount DESC) AS rn
    FROM aggregated ag
) a
WHERE a.rn <= 5
ORDER BY a.d_year DESC, a.d_month_seq DESC, a.total_return_amount DESC
LIMIT 100
