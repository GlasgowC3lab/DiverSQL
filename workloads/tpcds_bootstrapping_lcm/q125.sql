SELECT
    cc.cc_division_name,
    cc.cc_manager,
    cc.cc_country,
    cc.cc_tax_percentage,
    cc_open.d_year AS cc_open_year,
    cc_open.d_month_seq AS cc_open_month_seq,
    cc_closed.d_year AS cc_closed_year,
    cc_closed.d_month_seq AS cc_closed_month_seq,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_floor_space,
    s.s_gmt_offset AS store_gmt_offset,
    store_dt.d_year AS store_closed_year,
    store_dt.d_month_seq AS store_closed_month_seq,
    wr_dt.d_year AS return_year,
    wr_dt.d_month_seq AS return_month_seq,
    wr_dt.d_day_name AS return_day_name,
    refund_addr.ca_city AS refunded_city,
    refund_addr.ca_state AS refunded_state,
    return_addr.ca_city AS returning_city,
    return_addr.ca_state AS returning_state,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_fee) AS avg_fee,
    SUM(wr.wr_return_quantity) AS total_return_quantity
FROM web_returns wr
JOIN date_dim wr_dt
    ON wr.wr_returned_date_sk = wr_dt.d_date_sk
JOIN customer_address refund_addr
    ON wr.wr_refunded_addr_sk = refund_addr.ca_address_sk
JOIN customer_address return_addr
    ON wr.wr_returning_addr_sk = return_addr.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = wr_dt.d_date_sk
JOIN date_dim store_dt
    ON s.s_closed_date_sk = store_dt.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = wr_dt.d_date_sk
JOIN date_dim cc_closed
    ON cc.cc_closed_date_sk = cc_closed.d_date_sk
JOIN date_dim cc_open
    ON cc.cc_open_date_sk = cc_open.d_date_sk
GROUP BY
    cc.cc_division_name,
    cc.cc_manager,
    cc.cc_country,
    cc.cc_tax_percentage,
    cc_open.d_year,
    cc_open.d_month_seq,
    cc_closed.d_year,
    cc_closed.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_floor_space,
    s.s_gmt_offset,
    store_dt.d_year,
    store_dt.d_month_seq,
    wr_dt.d_year,
    wr_dt.d_month_seq,
    wr_dt.d_day_name,
    refund_addr.ca_city,
    refund_addr.ca_state,
    return_addr.ca_city,
    return_addr.ca_state
ORDER BY total_net_loss DESC
LIMIT 100
