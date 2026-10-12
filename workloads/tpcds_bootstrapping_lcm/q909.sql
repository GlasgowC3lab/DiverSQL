SELECT
    cc.cc_name AS call_center_name,
    cc.cc_state AS call_center_state,
    s.s_store_name,
    s.s_city AS store_city,
    d_closed.d_year AS cc_closed_year,
    d_closed.d_month_seq AS cc_closed_month_seq,
    d_open.d_year AS cc_open_year,
    d_open.d_month_seq AS cc_open_month_seq,
    d_returned.d_year AS return_year,
    d_returned.d_month_seq AS return_month_seq,
    ca_ret.ca_city AS returning_city,
    ca_ret.ca_state AS returning_state,
    ca_ref.ca_city AS refunded_city,
    ca_ref.ca_state AS refunded_state,
    COUNT(DISTINCT wr.wr_order_number) AS num_orders_returned,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    SUM(wr.wr_return_quantity) AS total_return_quantity
FROM web_returns wr
JOIN date_dim d_returned
    ON wr.wr_returned_date_sk = d_returned.d_date_sk
JOIN customer_address ca_ret
    ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ref
    ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_returned.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_returned.d_date_sk
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
WHERE d_returned.d_year BETWEEN 2000 AND 2002
  AND cc.cc_state = 'CA'
GROUP BY
    cc.cc_name,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    d_closed.d_year,
    d_closed.d_month_seq,
    d_open.d_year,
    d_open.d_month_seq,
    d_returned.d_year,
    d_returned.d_month_seq,
    ca_ret.ca_city,
    ca_ret.ca_state,
    ca_ref.ca_city,
    ca_ref.ca_state
ORDER BY total_net_loss DESC
LIMIT 100
