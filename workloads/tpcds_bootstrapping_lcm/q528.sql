SELECT
    c_refunded.c_customer_id AS refunded_customer_id,
    CONCAT(c_refunded.c_first_name, ' ', c_refunded.c_last_name) AS refunded_customer_name,
    c_returning.c_customer_id AS returning_customer_id,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_tax_percentage,
    wp.wp_type,
    wp.wp_url,
    d_creation.d_date AS page_creation_date,
    d_access.d_date AS page_access_date,
    d_cust_first_sales.d_date AS customer_first_sales_date,
    d_cust_first_shipto.d_date AS customer_first_shipto_date,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders_returned
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_refunded
    ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning
    ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
   AND wp.wp_customer_sk = c_refunded.c_customer_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN date_dim d_cust_first_sales
    ON c_refunded.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
JOIN date_dim d_cust_first_shipto
    ON c_refunded.c_first_shipto_date_sk = d_cust_first_shipto.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
GROUP BY
    c_refunded.c_customer_id,
    c_refunded.c_first_name,
    c_refunded.c_last_name,
    c_returning.c_customer_id,
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_tax_percentage,
    wp.wp_type,
    wp.wp_url,
    d_creation.d_date,
    d_access.d_date,
    d_cust_first_sales.d_date,
    d_cust_first_shipto.d_date
ORDER BY total_return_amount DESC
LIMIT 100
