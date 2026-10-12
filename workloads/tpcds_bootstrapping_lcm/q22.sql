SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_sr.d_year,
    d_sr.d_month_seq,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_txn_cnt,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_txn_cnt,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    COUNT(DISTINCT c_ref.c_customer_id) AS distinct_refunded_customers,
    MIN(d_sr.d_date) AS first_store_return_date,
    MAX(d_sr.d_date) AS last_store_return_date,
    MIN(d_wr.d_date) AS first_web_return_date,
    MAX(d_wr.d_date) AS last_web_return_date,
    d_store_closed.d_date AS store_closed_date,
    d_cust_first_ship.d_date AS customer_first_ship_date,
    d_cust_first_sales.d_date AS customer_first_sales_date,
    d_cust_last_review.d_date AS customer_last_review_date
FROM store s
JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
JOIN web_returns wr ON wr.wr_returning_customer_sk = c.c_customer_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN customer c_ref ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cust_first_ship ON c.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
JOIN date_dim d_cust_first_sales ON c.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
JOIN date_dim d_cust_last_review ON c.c_last_review_date = d_cust_last_review.d_date_sk
WHERE d_sr.d_year = 2020
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_sr.d_year,
    d_sr.d_month_seq,
    d_store_closed.d_date,
    d_cust_first_ship.d_date,
    d_cust_first_sales.d_date,
    d_cust_last_review.d_date
ORDER BY total_store_net_loss DESC
LIMIT 100
