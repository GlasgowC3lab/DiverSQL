SELECT
    cc.cc_name,
    cc.cc_manager,
    cc.cc_city,
    d_closed.d_date AS cc_closed_date,
    d_open.d_date AS cc_open_date,
    date_diff('day', d_open.d_date, d_closed.d_date) AS cc_days_open,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s_closed.d_date AS store_closed_date,
    w.web_name,
    w.web_city,
    w_open.d_date AS web_open_date,
    w_close.d_date AS web_close_date,
    date_diff('day', w_open.d_date, w_close.d_date) AS web_days_open,
    SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
    COUNT(DISTINCT i.inv_warehouse_sk) AS warehouse_count,
    CASE
        WHEN COUNT(DISTINCT i.inv_warehouse_sk) > 0
        THEN SUM(i.inv_quantity_on_hand) / COUNT(DISTINCT i.inv_warehouse_sk)
        ELSE NULL
    END AS avg_qty_per_warehouse
FROM call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN date_dim s_closed
    ON s.s_closed_date_sk = s_closed.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_closed.d_date_sk
JOIN web_site w
    ON w.web_open_date_sk = d_open.d_date_sk
JOIN date_dim w_open
    ON w.web_open_date_sk = w_open.d_date_sk
JOIN date_dim w_close
    ON w.web_close_date_sk = w_close.d_date_sk
WHERE d_closed.d_year = 2022
  AND i.inv_quantity_on_hand > 0
GROUP BY
    cc.cc_name,
    cc.cc_manager,
    cc.cc_city,
    d_closed.d_date,
    d_open.d_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s_closed.d_date,
    w.web_name,
    w.web_city,
    w_open.d_date,
    w_close.d_date
ORDER BY total_quantity_on_hand DESC
LIMIT 100
