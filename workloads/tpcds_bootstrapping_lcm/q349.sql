SELECT
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    CASE WHEN c.c_birth_country = 'USA' THEN 'Domestic' ELSE 'International' END AS birth_region,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_ext_discount_amt) AS total_discount,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_fee) AS total_return_fee,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    AVG(ss.ss_quantity) AS avg_quantity,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 0 THEN SUM(ss.ss_net_profit) / SUM(ss.ss_ext_sales_price) ELSE NULL END AS profit_margin,
    MIN(d_cust_shipto.d_date) AS first_shipto_date,
    MIN(d_cust_first_sales.d_date) AS first_sales_date,
    MAX(d_cust_last_review.d_date) AS last_review_date,
    MIN(d_return.d_date) AS first_return_date,
    MAX(d_return.d_date) AS last_return_date,
    MAX(d_store_closed.d_date) AS store_closed_date
FROM
    customer c
    JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
                         AND wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN date_dim d_store_closed ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_cust_shipto ON c.c_first_shipto_date_sk = d_cust_shipto.d_date_sk
    JOIN date_dim d_cust_first_sales ON c.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
    JOIN date_dim d_cust_last_review ON c.c_last_review_date = d_cust_last_review.d_date_sk
WHERE
    s.s_state = 'CA'
    AND d_sales.d_year BETWEEN 2000 AND 2005
    AND d_store_closed.d_year IS NOT NULL
    AND ss.ss_quantity > 0
GROUP BY
    s.s_store_name,
    d_sales.d_year,
    d_sales.d_month_seq,
    CASE WHEN c.c_birth_country = 'USA' THEN 'Domestic' ELSE 'International' END
HAVING
    SUM(ss.ss_ext_sales_price) > 1000
ORDER BY
    total_sales DESC
LIMIT 100
