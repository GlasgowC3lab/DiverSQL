WITH agg AS (
    SELECT
        w.w_state AS state,
        cp.cp_type AS catalog_type,
        ws.web_class AS web_class,
        SUM(w.w_warehouse_sq_ft) AS total_sq_ft,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages,
        AVG(ws.web_tax_percentage) AS avg_tax_pct
    FROM catalog_page cp
    JOIN warehouse w
        ON cp.cp_type = w.w_street_type
    JOIN web_site ws
        ON w.w_city = ws.web_city
        AND w.w_state = ws.web_state
        AND w.w_country = ws.web_country
        AND cp.cp_type = ws.web_street_type
    WHERE cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
      AND w.w_warehouse_sq_ft > 5000
      AND ws.web_tax_percentage > 5.0
    GROUP BY w.w_state, cp.cp_type, ws.web_class
)
SELECT
    state,
    catalog_type,
    web_class,
    total_sq_ft,
    distinct_pages,
    avg_tax_pct,
    RANK() OVER (ORDER BY total_sq_ft DESC) AS state_rank
FROM agg
ORDER BY state_rank, state
