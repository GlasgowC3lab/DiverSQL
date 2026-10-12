SELECT
    cc.cc_name,
    cc.cc_market_manager,
    s.s_store_name,
    s.s_city,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_quantity_on_hand,
    MAX(cc.cc_tax_percentage) AS max_cc_tax_pct,
    MIN(s.s_tax_percentage) AS min_store_tax_pct,
    d_cc_open.d_date AS call_center_open_date,
    d_store.d_date AS store_closed_date,
    CASE WHEN d_store.d_weekend = 'Y' THEN 'Weekend' ELSE 'Weekday' END AS store_closed_day_type
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_ret.d_date_sk
WHERE
    d_ret.d_year = 2001
    AND s.s_state = 'CA'
    AND cc.cc_tax_percentage > 5.0
GROUP BY
    cc.cc_name,
    cc.cc_market_manager,
    s.s_store_name,
    s.s_city,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_cc_open.d_date,
    d_store.d_date,
    d_store.d_weekend
ORDER BY total_return_amount DESC
LIMIT 100
