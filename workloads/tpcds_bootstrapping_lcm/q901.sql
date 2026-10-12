SELECT 
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    cc.cc_city,
    cc.cc_gmt_offset,
    d_closed.d_date AS closed_date,
    d_closed.d_year AS closed_year,
    d_open.d_date AS open_date,
    d_open.d_year AS open_year,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_city,
    s.s_gmt_offset,
    d_closed.d_month_seq AS closed_month_seq,
    d_closed.d_day_name AS closed_day_name,
    wr.wr_order_number,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_return_tax,
    wr.wr_net_loss,
    (wr.wr_return_amt + wr.wr_return_tax) AS total_return_amount,
    ca_refunded.ca_country AS refunded_country,
    ca_refunded.ca_state AS refunded_state,
    ca_refunded.ca_city AS refunded_city,
    ca_returning.ca_country AS returning_country,
    ca_returning.ca_state AS returning_state,
    ca_returning.ca_city AS returning_city,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY (wr.wr_return_amt + wr.wr_return_tax) DESC) AS store_return_rank
FROM web_returns wr
JOIN date_dim d_closed
    ON wr.wr_returned_date_sk = d_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
LEFT JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
LEFT JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
LEFT JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
WHERE d_closed.d_year = 2022
ORDER BY total_return_amount DESC
LIMIT 100
