SELECT
    cp.cp_department,
    ws.web_name,
    sd.d_fy_year AS fiscal_year,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_page_count,
    AVG(cp.cp_catalog_number) AS avg_catalog_number,
    MAX(ws.web_tax_percentage) AS max_tax_percentage
FROM catalog_page cp
JOIN date_dim sd ON cp.cp_start_date_sk = sd.d_date_sk
JOIN date_dim ed ON cp.cp_end_date_sk = ed.d_date_sk
JOIN web_site ws ON cp.cp_start_date_sk <= ws.web_close_date_sk
                 AND cp.cp_end_date_sk >= ws.web_open_date_sk
JOIN date_dim od ON ws.web_open_date_sk = od.d_date_sk
JOIN date_dim cd ON ws.web_close_date_sk = cd.d_date_sk
WHERE cp.cp_type = 'monthly'
  AND cp.cp_department = 'DEPARTMENT'
  AND ws.web_state = 'CA'
GROUP BY cp.cp_department, ws.web_name, sd.d_fy_year
HAVING COUNT(DISTINCT cp.cp_catalog_page_id) >= 5
ORDER BY fiscal_year DESC, distinct_page_count DESC
LIMIT 100
