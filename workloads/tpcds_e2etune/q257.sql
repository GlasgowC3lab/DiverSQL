WITH agg AS (
    SELECT
        cp.cp_department,
        s.s_state,
        sm.sm_type,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        AVG(i.inv_quantity_on_hand) AS avg_quantity,
        COUNT(*) AS inventory_records,
        COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_pages,
        COUNT(DISTINCT cd.cd_education_status) AS distinct_education_status,
        AVG(td.t_hour) AS avg_hour,
        MAX(td.t_hour) AS max_hour
    FROM inventory i
    JOIN catalog_page cp ON i.inv_item_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON i.inv_date_sk = td.t_time_sk
    JOIN store s ON i.inv_warehouse_sk = s.s_store_sk
    JOIN ship_mode sm ON i.inv_warehouse_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON cp.cp_catalog_page_id = wp.wp_web_page_id
    JOIN customer_demographics cd ON i.inv_item_sk = cd.cd_demo_sk
    WHERE cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
      AND s.s_closed_date_sk IS NULL
      AND td.t_hour BETWEEN 8 AND 20
      AND sm.sm_type IS NOT NULL
      AND cd.cd_gender = 'F'
    GROUP BY cp.cp_department, s.s_state, sm.sm_type
    HAVING SUM(i.inv_quantity_on_hand) > 5000
)
SELECT
    cp_department,
    s_state,
    sm_type,
    total_quantity,
    avg_quantity,
    inventory_records,
    distinct_pages,
    distinct_education_status,
    avg_hour,
    max_hour,
    RANK() OVER (ORDER BY total_quantity DESC) AS quantity_rank
FROM agg
ORDER BY total_quantity DESC
LIMIT 100
