WITH aggregated AS (
    SELECT
        i.inv_warehouse_sk,
        d.d_year,
        d.d_month_seq,
        d.d_date_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    GROUP BY i.inv_warehouse_sk, d.d_year, d.d_month_seq, d.d_date_sk
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    a.d_year,
    a.d_month_seq,
    a.total_quantity,
    a.distinct_items,
    COUNT(DISTINCT s.s_store_sk) AS stores_closed,
    MAX(s.s_number_employees) AS max_employees,
    MAX(s.s_tax_percentage) AS tax_rate,
    a.total_quantity * MAX(s.s_tax_percentage) AS tax_adjusted_quantity,
    COUNT(DISTINCT wp.wp_web_page_sk) AS web_pages_created,
    SUM(wp.wp_image_count) AS total_images,
    AVG(wp.wp_link_count) AS avg_links,
    MAX(d_store.d_holiday) AS store_closed_holiday,
    MAX(d_access.d_day_name) AS latest_access_day_name,
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_quantity DESC) AS yearly_warehouse_rank,
    RANK() OVER (PARTITION BY w.w_state ORDER BY a.total_quantity DESC) AS state_warehouse_rank
FROM aggregated a
JOIN warehouse w ON a.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store s ON s.s_closed_date_sk = a.d_date_sk
LEFT JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
LEFT JOIN web_page wp ON wp.wp_creation_date_sk = a.d_date_sk
LEFT JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE a.d_year = 2023
  AND w.w_state = 'CA'
GROUP BY
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    a.d_year,
    a.d_month_seq,
    a.total_quantity,
    a.distinct_items
ORDER BY total_quantity DESC, w.w_warehouse_name
