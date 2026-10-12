SELECT
    s.s_city,
    s.s_state,
    d_store.d_current_year AS store_close_year,
    d_return.d_current_quarter AS return_quarter,
    d_ship.d_current_month AS ship_month,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_fee) AS avg_fee,
    COUNT(DISTINCT cust_refunded.c_customer_id) AS unique_refunded_customers,
    COUNT(DISTINCT cust_returning.c_customer_id) AS unique_returning_customers
FROM web_returns wr
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN customer cust_refunded
    ON wr.wr_refunded_customer_sk = cust_refunded.c_customer_sk
JOIN customer cust_returning
    ON wr.wr_returning_customer_sk = cust_returning.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN date_dim d_ship
    ON cust_refunded.c_first_shipto_date_sk = d_ship.d_date_sk
WHERE d_return.d_year = 2022
  AND d_store.d_year = 2022
GROUP BY
    s.s_city,
    s.s_state,
    d_store.d_current_year,
    d_return.d_current_quarter,
    d_ship.d_current_month
ORDER BY total_net_loss DESC
LIMIT 100
