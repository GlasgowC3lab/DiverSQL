SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year AS store_event_year,
    d.d_month_seq AS store_event_month,
    d_cust_sales.d_year AS customer_first_sales_year,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca_current.ca_state AS current_address_state,
    ca_refund.ca_state AS refund_address_state,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_net_loss) AS total_net_loss
FROM store s
JOIN date_dim d
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer c
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN date_dim d_cust_sales
    ON c.c_first_sales_date_sk = d_cust_sales.d_date_sk
JOIN customer_address ca_refund
    ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_current
    ON c.c_current_addr_sk = ca_current.ca_address_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_year,
    d.d_month_seq,
    d_cust_sales.d_year,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca_current.ca_state,
    ca_refund.ca_state
ORDER BY total_return_amount DESC
LIMIT 100
