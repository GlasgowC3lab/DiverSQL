SELECT
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    COUNT(DISTINCT cust_sales.c_customer_id) AS num_customers,
    COUNT(DISTINCT cust_refunded.c_customer_id) AS num_refunded_customers,
    COUNT(DISTINCT cust_returning.c_customer_id) AS num_returning_customers,
    MAX(d_store_closed.d_date) AS store_closed_date,
    MIN(d_cust_first_sales.d_date) AS first_customer_sales_date,
    MAX(d_cust_last_review.d_date) AS last_customer_review_date
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN customer cust_sales
    ON ss.ss_customer_sk = cust_sales.c_customer_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sales.d_date_sk
LEFT JOIN customer cust_refunded
    ON wr.wr_refunded_customer_sk = cust_refunded.c_customer_sk
LEFT JOIN customer cust_returning
    ON wr.wr_returning_customer_sk = cust_returning.c_customer_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
LEFT JOIN date_dim d_cust_first_sales
    ON cust_sales.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
LEFT JOIN date_dim d_cust_first_ship
    ON cust_sales.c_first_shipto_date_sk = d_cust_first_ship.d_date_sk
LEFT JOIN date_dim d_cust_last_review
    ON cust_sales.c_last_review_date = d_cust_last_review.d_date_sk
WHERE d_sales.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq
ORDER BY total_sales_amount DESC
LIMIT 10
