SELECT
    d.d_year AS year,
    d.d_quarter_seq AS quarter,
    cc.cc_state AS call_center_state,
    s.s_state AS store_state,
    cp.cp_type AS catalog_page_type,
    CASE WHEN cc.cc_tax_percentage > 5 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
    cc.cc_state || '-' || s.s_state AS combined_state,
    CAST(s.s_floor_space / 1000 AS integer) AS floor_space_k,
    COUNT(DISTINCT cc.cc_call_center_id) AS num_call_centers,
    COUNT(DISTINCT s.s_store_id) AS num_stores,
    COUNT(DISTINCT cp.cp_catalog_page_id) AS num_catalog_pages,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_qty,
    SUM(s.s_floor_space) AS total_store_floor_space,
    ROUND(AVG(cc.cc_tax_percentage), 2) AS avg_call_center_tax,
    ROUND(AVG(s.s_tax_percentage), 2) AS avg_store_tax,
    SUM(i.inv_quantity_on_hand * (cc.cc_tax_percentage + s.s_tax_percentage) / 200) AS weighted_taxed_inventory
FROM call_center cc
JOIN date_dim d
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
GROUP BY
    d.d_year,
    d.d_quarter_seq,
    cc.cc_state,
    s.s_state,
    cp.cp_type,
    CASE WHEN cc.cc_tax_percentage > 5 THEN 'HighTax' ELSE 'LowTax' END,
    cc.cc_state || '-' || s.s_state,
    CAST(s.s_floor_space / 1000 AS integer)
ORDER BY
    d.d_year,
    d.d_quarter_seq
LIMIT 100
