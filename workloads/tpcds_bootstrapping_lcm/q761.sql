SELECT
    cc.cc_division_name,
    cc.cc_state,
    dd_cc.d_year AS cc_closed_year,
    dd_cc.d_month_seq AS cc_closed_month_seq,
    s.s_state AS store_state,
    s.s_city AS store_city,
    dd_store.d_year AS store_closed_year,
    dd_store.d_month_seq AS store_closed_month_seq,
    i.i_category,
    i.i_brand,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    AVG(sr.sr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    AVG(s.s_floor_space) AS avg_floor_space,
    SUM(sr.sr_return_amt) / NULLIF(AVG(s.s_floor_space), 0) AS return_per_sqft
FROM call_center cc
JOIN date_dim dd_cc
    ON cc.cc_closed_date_sk = dd_cc.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = dd_cc.d_date_sk
JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dd_store
    ON s.s_closed_date_sk = dd_store.d_date_sk
WHERE
    cc.cc_state IS NOT NULL
    AND s.s_state IS NOT NULL
    AND i.i_category IS NOT NULL
GROUP BY
    cc.cc_division_name,
    cc.cc_state,
    dd_cc.d_year,
    dd_cc.d_month_seq,
    s.s_state,
    s.s_city,
    dd_store.d_year,
    dd_store.d_month_seq,
    i.i_category,
    i.i_brand
ORDER BY total_return_amount DESC
LIMIT 100
