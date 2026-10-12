SELECT
    cc.cc_company_name,
    cc.cc_manager,
    d_open.d_year AS call_center_open_year,
    d_open.d_month_seq AS call_center_open_month,
    d_closed.d_year AS call_center_closed_year,
    d_closed.d_month_seq AS call_center_closed_month,
    ws.web_name,
    ws.web_manager,
    s.s_store_name,
    s.s_manager,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_close_date,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items_on_close_date,
    COUNT(DISTINCT s.s_store_sk) AS stores_closed_same_day,
    COUNT(DISTINCT ws.web_site_sk) AS websites_active_same_day,
    ROUND(SUM(i.inv_quantity_on_hand) * 1.0 / NULLIF(COUNT(DISTINCT s.s_store_sk), 0), 2) AS avg_inventory_per_store
FROM call_center cc
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_open.d_date_sk
   AND ws.web_close_date_sk = d_closed.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_closed.d_date_sk
GROUP BY
    cc.cc_company_name,
    cc.cc_manager,
    d_open.d_year,
    d_open.d_month_seq,
    d_closed.d_year,
    d_closed.d_month_seq,
    ws.web_name,
    ws.web_manager,
    s.s_store_name,
    s.s_manager
ORDER BY total_inventory_on_close_date DESC
LIMIT 100
