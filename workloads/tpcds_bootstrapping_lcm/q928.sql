SELECT
    cc.cc_company_name,
    d_closed.d_year,
    d_closed.d_month_seq,
    date_diff('day', d_open.d_date, d_closed.d_date) AS days_open,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
    SUM(i.inv_quantity_on_hand) AS total_quantity,
    AVG(s.s_number_employees) AS avg_store_employees,
    SUM(CASE WHEN s.s_state = cc.cc_state THEN 1 ELSE 0 END) AS same_state_store_count
FROM call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE d_closed.d_year = 2020
GROUP BY
    cc.cc_company_name,
    d_closed.d_year,
    d_closed.d_month_seq,
    date_diff('day', d_open.d_date, d_closed.d_date)
HAVING SUM(i.inv_quantity_on_hand) > 1000
ORDER BY total_quantity DESC
LIMIT 100
