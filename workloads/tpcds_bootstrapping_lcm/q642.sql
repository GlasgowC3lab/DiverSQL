WITH store_closure AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_number_employees,
        s.s_closed_date_sk,
        d.d_date AS closure_date,
        d.d_year,
        d.d_quarter_name
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_closed_date_sk IS NOT NULL
),
store_aggregates AS (
    SELECT
        sc.s_store_id,
        sc.s_store_name,
        sc.s_city,
        sc.s_state,
        sc.closure_date,
        sc.d_year,
        sc.d_quarter_name,
        COALESCE(SUM(i.inv_quantity_on_hand), 0) AS total_inventory_on_closure,
        COALESCE(SUM(i.inv_quantity_on_hand) / NULLIF(sc.s_number_employees, 0), 0) AS inventory_per_employee,
        COUNT(DISTINCT wp.wp_web_page_sk) AS web_pages_created_on_closure,
        COALESCE(SUM(wp.wp_image_count), 0) AS total_image_count,
        COALESCE(SUM(wp.wp_link_count), 0) AS total_link_count,
        SUM(CASE WHEN d_access.d_date = sc.closure_date THEN 1 ELSE 0 END) AS pages_accessed_same_day,
        AVG(wp.wp_char_count) AS avg_char_count
    FROM store_closure sc
    LEFT JOIN inventory i
        ON i.inv_date_sk = sc.s_closed_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = sc.s_closed_date_sk
    LEFT JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    GROUP BY
        sc.s_store_id,
        sc.s_store_name,
        sc.s_city,
        sc.s_state,
        sc.closure_date,
        sc.d_year,
        sc.d_quarter_name,
        sc.s_number_employees
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.s_city,
    sa.s_state,
    sa.closure_date,
    sa.d_year,
    sa.d_quarter_name,
    sa.total_inventory_on_closure,
    sa.inventory_per_employee,
    sa.web_pages_created_on_closure,
    sa.total_image_count,
    sa.total_link_count,
    sa.pages_accessed_same_day,
    sa.avg_char_count,
    RANK() OVER (ORDER BY sa.total_inventory_on_closure DESC) AS inventory_rank
FROM store_aggregates sa
ORDER BY inventory_rank
LIMIT 100
