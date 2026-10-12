WITH
    call_center_events AS (
        SELECT
            cc.cc_name,
            cc.cc_gmt_offset,
            cc.cc_open_date_sk AS date_sk,
            d.d_date AS open_date
        FROM call_center cc
        JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    web_site_events AS (
        SELECT
            ws.web_name,
            ws.web_gmt_offset,
            ws.web_open_date_sk AS date_sk,
            d.d_date AS open_date
        FROM web_site ws
        JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
    ),
    inventory_agg AS (
        SELECT
            d.d_date,
            i.inv_warehouse_sk,
            i.inv_quantity_on_hand
        FROM inventory i
        JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
        WHERE i.inv_quantity_on_hand > 0
          AND d.d_year = 2001
    ),
    cross_dim AS (
        SELECT ws.web_company_id, ws.web_company_name
        FROM web_site ws
        WHERE ws.web_company_id IN (2, 3)
        LIMIT 2
    ),
    years_set AS (
        SELECT DISTINCT d_year FROM date_dim WHERE d_year = 2001
    ),
    cross_joined AS (
        SELECT cd.web_company_id, cd.web_company_name, y.d_year
        FROM cross_dim cd CROSS JOIN years_set y
    ),
    demo_rows AS (
        SELECT
            date_add('day', seq - 1, DATE '2001-01-01') AS event_date,
            CONCAT('Demo_', cj.web_company_name) AS entity_name,
            'Demo' AS entity_type,
            NULL AS gmt_offset
        FROM cross_joined cj
        CROSS JOIN (VALUES (1), (2), (3)) AS t(seq)
    ),
    combined AS (
        -- Full outer join between call_center and web_site on the surrogate date key
        SELECT
            COALESCE(ce.open_date, we.open_date) AS event_date,
            COALESCE(ce.cc_name, we.web_name) AS entity_name,
            CASE
                WHEN ce.cc_name IS NOT NULL THEN 'CallCenter'
                WHEN we.web_name IS NOT NULL THEN 'WebSite'
                ELSE 'Unknown'
            END AS entity_type,
            ROUND(COALESCE(ce.cc_gmt_offset, we.web_gmt_offset), 2) AS gmt_offset
        FROM call_center_events ce
        FULL OUTER JOIN web_site_events we ON ce.date_sk = we.date_sk
        UNION ALL
        -- Inventory rows
        SELECT
            i.d_date AS event_date,
            CONCAT('InvWH_', CAST(i.inv_warehouse_sk AS varchar)) AS entity_name,
            'Inventory' AS entity_type,
            NULL AS gmt_offset
        FROM inventory_agg i
        UNION ALL
        -- Demo rows created via a CROSS JOIN
        SELECT
            dr.event_date,
            dr.entity_name,
            dr.entity_type,
            dr.gmt_offset
        FROM demo_rows dr
    )
SELECT *
FROM (
    SELECT
        c.*, 
        ROW_NUMBER() OVER (
            PARTITION BY event_date 
            ORDER BY 
                CASE WHEN gmt_offset IS NULL THEN 1 ELSE 0 END, 
                gmt_offset DESC
        ) AS rn
    FROM combined c
) t
WHERE rn <= 5
ORDER BY event_date DESC, entity_type
LIMIT 100
