WITH store_catalog AS (
    SELECT
        s.s_store_sk,
        s.s_state,
        s.s_city,
        s.s_tax_percentage AS store_tax,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_type,
        cp.cp_end_date_sk
    FROM store s
    JOIN catalog_page cp
        ON s.s_closed_date_sk = cp.cp_end_date_sk
    WHERE s.s_closed_date_sk IS NOT NULL
),
store_web AS (
    SELECT
        sc.s_state,
        sc.s_city,
        sc.s_store_sk,
        sc.cp_department,
        sc.cp_catalog_number,
        sc.cp_type,
        sc.store_tax,
        ws.web_tax_percentage,
        ws.web_name,
        ws.web_gmt_offset
    FROM store_catalog sc
    JOIN web_site ws
        ON sc.s_state = ws.web_state
        AND sc.s_city = ws.web_city
    WHERE ws.web_open_date_sk IS NOT NULL
)
SELECT
    sw.s_state,
    sw.s_city,
    COUNT(DISTINCT sw.s_store_sk) AS store_count,
    COUNT(DISTINCT sw.cp_catalog_number) AS distinct_catalogs,
    AVG(sw.store_tax) AS avg_store_tax,
    AVG(sw.web_tax_percentage) AS avg_web_tax,
    MIN(sw.web_gmt_offset) AS min_web_gmt_offset,
    MAX(sw.web_gmt_offset) AS max_web_gmt_offset,
    SUM(CASE WHEN sw.cp_type = 'Promotion' THEN 1 ELSE 0 END) AS promo_pages,
    RANK() OVER (ORDER BY COUNT(DISTINCT sw.s_store_sk) DESC) AS state_store_rank
FROM store_web sw
WHERE sw.cp_department = 'DEPARTMENT'
GROUP BY sw.s_state, sw.s_city
ORDER BY store_count DESC
LIMIT 100
