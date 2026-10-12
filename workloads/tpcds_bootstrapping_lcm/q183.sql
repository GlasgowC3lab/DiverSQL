SELECT 
    cc.cc_call_center_id,
    cc.cc_city,
    cc.cc_state,
    d_cc_closed.d_year AS cc_closed_year,
    d_cc_open.d_year   AS cc_open_year,
    s.s_store_id,
    s.s_city   AS store_city,
    s.s_state  AS store_state,
    d_store_closed.d_year AS store_closed_year,
    r.r_reason_desc,
    d_wr.d_year AS return_year,
    SUM(wr.wr_return_amt)       AS total_return_amount,
    SUM(wr.wr_net_loss)         AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_fee)              AS total_fee
FROM web_returns wr
JOIN date_dim d_wr
     ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN reason r
     ON wr.wr_reason_sk = r.r_reason_sk
JOIN call_center cc
     ON cc.cc_closed_date_sk = d_wr.d_date_sk
JOIN date_dim d_cc_closed
     ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN date_dim d_cc_open
     ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s
     ON s.s_closed_date_sk = d_wr.d_date_sk
JOIN date_dim d_store_closed
     ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_wr.d_year = 2020
  AND cc.cc_division = s.s_division_id
GROUP BY 
    cc.cc_call_center_id,
    cc.cc_city,
    cc.cc_state,
    d_cc_closed.d_year,
    d_cc_open.d_year,
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_store_closed.d_year,
    r.r_reason_desc,
    d_wr.d_year
ORDER BY total_return_amount DESC
LIMIT 100
