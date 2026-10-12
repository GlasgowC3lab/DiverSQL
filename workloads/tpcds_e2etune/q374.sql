SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_type,
    COUNT(r.r_reason_sk) AS reason_match_count,
    SUM(cp.cp_catalog_page_number) AS total_page_numbers,
    MIN(cp.cp_start_date_sk) AS earliest_start_date,
    MAX(cp.cp_end_date_sk) AS latest_end_date
FROM catalog_page cp
JOIN reason r
    ON cp.cp_catalog_page_number = r.r_reason_sk
WHERE cp.cp_department = 'DEPARTMENT'
    AND cp.cp_catalog_page_number BETWEEN 1 AND 6
    AND cp.cp_start_date_sk >= 2450800
GROUP BY cp.cp_department, cp.cp_catalog_number, cp.cp_type
HAVING COUNT(r.r_reason_sk) > 0
ORDER BY total_page_numbers DESC, reason_match_count ASC
