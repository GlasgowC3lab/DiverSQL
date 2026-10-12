SELECT
    cc.cc_division_name,
    s.s_division_name,
    w.w_city,
    d_inv.d_year AS inventory_year,
    CASE
        WHEN d_cc_open.d_moy = d_cc_closed.d_moy THEN 'SameMonth'
        ELSE 'DifferentMonth'
    END AS open_closed_month_flag,
    SUM(i.inv_quantity_on_hand) AS total_qty,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    CAST(SUM(i.inv_quantity_on_hand) AS double) / NULLIF(COUNT(DISTINCT i.inv_item_sk), 0) AS avg_qty_per_item
FROM call_center cc
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_inv
    ON i.inv_date_sk = d_inv.d_date_sk
JOIN warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
WHERE d_cc_closed.d_year BETWEEN 2015 AND 2020
  AND w.w_state = s.s_state
  AND cc.cc_tax_percentage > 0
GROUP BY
    cc.cc_division_name,
    s.s_division_name,
    w.w_city,
    d_inv.d_year,
    CASE
        WHEN d_cc_open.d_moy = d_cc_closed.d_moy THEN 'SameMonth'
        ELSE 'DifferentMonth'
    END
HAVING SUM(i.inv_quantity_on_hand) > 5000
ORDER BY total_qty DESC
LIMIT 100
