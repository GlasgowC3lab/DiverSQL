SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_returned.d_date AS return_date,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    c_returning.c_customer_id AS returning_customer_id,
    c_returning.c_first_name || ' ' || c_returning.c_last_name AS returning_customer_name,
    ca_returning.ca_city AS returning_address_city,
    ca_returning.ca_state AS returning_address_state,
    ca_current_returning.ca_city AS returning_current_address_city,
    ca_current_returning.ca_state AS returning_current_address_state,
    d_first_shipto_returning.d_date AS returning_first_shipto_date,
    d_first_sales_returning.d_date AS returning_first_sales_date,
    c_refunded.c_customer_id AS refunded_customer_id,
    c_refunded.c_first_name || ' ' || c_refunded.c_last_name AS refunded_customer_name,
    ca_refunded.ca_city AS refunded_address_city,
    ca_refunded.ca_state AS refunded_address_state,
    ca_current_refunded.ca_city AS refunded_current_address_city,
    ca_current_refunded.ca_state AS refunded_current_address_state
FROM web_returns wr
JOIN date_dim d_returned
    ON wr.wr_returned_date_sk = d_returned.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_returned.d_date_sk
JOIN customer c_refunded
    ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer c_returning
    ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN customer_address ca_current_returning
    ON c_returning.c_current_addr_sk = ca_current_returning.ca_address_sk
JOIN customer_address ca_current_refunded
    ON c_refunded.c_current_addr_sk = ca_current_refunded.ca_address_sk
JOIN date_dim d_first_shipto_returning
    ON c_returning.c_first_shipto_date_sk = d_first_shipto_returning.d_date_sk
JOIN date_dim d_first_sales_returning
    ON c_returning.c_first_sales_date_sk = d_first_sales_returning.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_returned.d_date,
    c_returning.c_customer_id,
    c_returning.c_first_name,
    c_returning.c_last_name,
    ca_returning.ca_city,
    ca_returning.ca_state,
    ca_current_returning.ca_city,
    ca_current_returning.ca_state,
    d_first_shipto_returning.d_date,
    d_first_sales_returning.d_date,
    c_refunded.c_customer_id,
    c_refunded.c_first_name,
    c_refunded.c_last_name,
    ca_refunded.ca_city,
    ca_refunded.ca_state,
    ca_current_refunded.ca_city,
    ca_current_refunded.ca_state
ORDER BY total_net_loss DESC
LIMIT 100
