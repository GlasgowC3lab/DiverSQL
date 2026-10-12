SELECT
    cd_return.d_year AS return_year,
    cd_return.d_month_seq AS return_month,
    cc.cc_division_name AS call_center_division,
    s.s_division_name AS store_division,
    ca_returning.ca_state AS returning_state,
    ca_refunded.ca_state AS refunded_state,
    CASE WHEN wr.wr_return_amt > 100 THEN 'High' ELSE 'Low' END AS return_amount_category,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_fee) AS total_fee,
    SUM(CASE WHEN wr.wr_fee > 0 THEN 1 ELSE 0 END) AS fee_count,
    AVG(DATE_DIFF('day', cd_cc_open.d_date, cd_return.d_date)) AS avg_operating_days
FROM web_returns wr
JOIN date_dim cd_return
    ON wr.wr_returned_date_sk = cd_return.d_date_sk
JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = cd_return.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = cd_return.d_date_sk
JOIN date_dim cd_cc_open
    ON cc.cc_open_date_sk = cd_cc_open.d_date_sk
GROUP BY
    cd_return.d_year,
    cd_return.d_month_seq,
    cc.cc_division_name,
    s.s_division_name,
    ca_returning.ca_state,
    ca_refunded.ca_state,
    CASE WHEN wr.wr_return_amt > 100 THEN 'High' ELSE 'Low' END
ORDER BY
    return_year,
    return_month,
    call_center_division,
    store_division
