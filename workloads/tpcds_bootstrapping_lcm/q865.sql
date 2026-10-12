SELECT
    d.d_year,
    d.d_moy AS month,
    cc.cc_division_name,
    s.s_division_name,
    ws.web_mkt_class,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct,
    AVG(s.s_tax_percentage) AS avg_store_tax_pct,
    AVG(ws.web_tax_percentage) AS avg_web_tax_pct,
    AVG(DATE_DIFF('day', d_cc_open.d_date, d.d_date)) AS avg_cc_days_to_close,
    AVG(DATE_DIFF('day', d.d_date, d_ws_close.d_date)) AS avg_web_days_open,
    CASE WHEN SUM(i.inv_quantity_on_hand) > 50000 THEN 'HIGH' ELSE 'NORMAL' END AS inventory_category
FROM date_dim d
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
GROUP BY
    d.d_year,
    d.d_moy,
    cc.cc_division_name,
    s.s_division_name,
    ws.web_mkt_class
HAVING SUM(i.inv_quantity_on_hand) > 0
ORDER BY total_inventory_qty DESC
LIMIT 100
