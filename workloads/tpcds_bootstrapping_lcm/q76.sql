SELECT
    cp.cp_type,
    s.s_state,
    ws.web_state,
    d_start.d_year AS start_year,
    (d_start.d_month_seq % 12 + 1) AS start_month,
    CASE
        WHEN c.c_birth_month IN (12, 1, 2) THEN 'Winter'
        WHEN c.c_birth_month IN (3, 4, 5) THEN 'Spring'
        WHEN c.c_birth_month IN (6, 7, 8) THEN 'Summer'
        WHEN c.c_birth_month IN (9, 10, 11) THEN 'Fall'
        ELSE 'Unknown'
    END AS birth_season,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    SUM(CASE WHEN d_start.d_date >= DATE '2022-01-01' THEN 1 ELSE 0 END) AS recent_pages,
    AVG(CAST(s.s_tax_percentage AS DOUBLE)) AS avg_store_tax,
    MAX(ws.web_tax_percentage) AS max_web_tax,
    SUM(CAST(ws.web_gmt_offset AS DOUBLE) * CAST(s.s_gmt_offset AS DOUBLE)) AS total_gmt_offset_product
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_start.d_date_sk
JOIN date_dim d_web_close
    ON ws.web_close_date_sk = d_web_close.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
JOIN customer c
    ON c.c_first_shipto_date_sk = d_start.d_date_sk
   AND c.c_first_sales_date_sk = d_end.d_date_sk
GROUP BY
    cp.cp_type,
    s.s_state,
    ws.web_state,
    d_start.d_year,
    (d_start.d_month_seq % 12 + 1),
    CASE
        WHEN c.c_birth_month IN (12, 1, 2) THEN 'Winter'
        WHEN c.c_birth_month IN (3, 4, 5) THEN 'Spring'
        WHEN c.c_birth_month IN (6, 7, 8) THEN 'Summer'
        WHEN c.c_birth_month IN (9, 10, 11) THEN 'Fall'
        ELSE 'Unknown'
    END
ORDER BY total_rows DESC
LIMIT 100
