SELECT
    s.s_state,
    d_closed.d_year,
    d_closed.d_month_seq,
    d_cp_end.d_quarter_seq AS catalog_end_quarter,
    COUNT(DISTINCT cc.cc_call_center_sk) AS num_closed_call_centers,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    AVG(s.s_tax_percentage) AS avg_store_tax_percentage,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS distinct_catalog_pages,
    CASE
        WHEN SUM(i.inv_quantity_on_hand) > 100000 THEN 'HIGH'
        WHEN SUM(i.inv_quantity_on_hand) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS inventory_category
FROM store s
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_open.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_open.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE d_closed.d_year = 2022
  AND s.s_state IS NOT NULL
GROUP BY
    s.s_state,
    d_closed.d_year,
    d_closed.d_month_seq,
    d_cp_end.d_quarter_seq
HAVING SUM(i.inv_quantity_on_hand) > 1000
ORDER BY total_inventory_qty DESC
LIMIT 100
