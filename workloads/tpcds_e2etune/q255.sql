WITH cp_agg AS (
    SELECT cp_type,
           cp_department,
           COUNT(*) AS cp_cnt,
           AVG(cp_catalog_page_number) AS avg_page_num,
           MIN(cp_start_date_sk) AS min_start_date,
           MAX(cp_end_date_sk) AS max_end_date
    FROM catalog_page
    WHERE cp_catalog_number IN (1, 2, 3)
      AND cp_type IN ('bi-annual', 'quarterly')
    GROUP BY cp_type, cp_department
),
sm_agg AS (
    SELECT sm_type,
           sm_carrier,
           COUNT(*) AS sm_cnt,
           COUNT(DISTINCT sm_ship_mode_id) AS distinct_modes
    FROM ship_mode
    WHERE sm_type IN ('AIR', 'GROUND')
    GROUP BY sm_type, sm_carrier
),
ws_agg AS (
    SELECT web_state,
           web_country,
           COUNT(*) AS ws_cnt,
           AVG(web_gmt_offset) AS avg_gmt_offset,
           SUM(web_tax_percentage) AS total_tax
    FROM web_site
    WHERE web_state IS NOT NULL
      AND web_gmt_offset BETWEEN -12 AND 14
    GROUP BY web_state, web_country
)
SELECT cp.cp_type,
       cp.cp_department,
       sm.sm_type,
       sm.sm_carrier,
       ws.web_state,
       ws.web_country,
       cp.cp_cnt,
       sm.sm_cnt,
       ws.ws_cnt,
       cp.avg_page_num,
       sm.distinct_modes,
       ws.avg_gmt_offset,
       ws.total_tax
FROM cp_agg cp
CROSS JOIN sm_agg sm
CROSS JOIN ws_agg ws
ORDER BY cp.cp_cnt DESC, sm.sm_cnt DESC
LIMIT 100
