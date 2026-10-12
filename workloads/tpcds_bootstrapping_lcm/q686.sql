SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year AS inventory_year,
    d.d_month_seq AS inventory_month,
    wp.wp_type,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_qty,
    MIN(d.d_date) AS earliest_inventory_date,
    MAX(d.d_date) AS latest_inventory_date,
    AVG(DATE_DIFF('day', d.d_date, d_access.d_date)) AS avg_days_between_creation_and_access,
    CASE WHEN d.d_year = d_access.d_year THEN 'SameYear' ELSE 'DiffYear' END AS year_match
FROM inventory i
JOIN date_dim d
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
WHERE i.inv_quantity_on_hand > 0
  AND s.s_state = 'CA'
  AND wp.wp_type IS NOT NULL
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_month_seq,
    wp.wp_type,
    d_access.d_year
HAVING SUM(i.inv_quantity_on_hand) > 1000
ORDER BY total_inventory_qty DESC
LIMIT 50
