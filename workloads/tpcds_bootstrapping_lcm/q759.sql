SELECT
    cp.cp_department,
    s.s_state,
    d_wr.d_year AS return_year,
    d_cust_shipto.d_month_seq AS cust_ship_month_seq,
    d_cust_sales.d_year AS cust_sales_year,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT c_refunded.c_customer_id) AS distinct_refunded_customers,
    COUNT(DISTINCT c_returning.c_customer_id) AS distinct_returning_customers
FROM web_returns wr
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = d_wr.d_date_sk
JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_wr.d_date_sk
JOIN date_dim d_cust_shipto ON c_refunded.c_first_shipto_date_sk = d_cust_shipto.d_date_sk
JOIN date_dim d_cust_sales ON c_returning.c_first_sales_date_sk = d_cust_sales.d_date_sk
WHERE d_wr.d_year BETWEEN 2000 AND 2020
  AND s.s_state IS NOT NULL
  AND cp.cp_type = 'PROMO'
GROUP BY
    cp.cp_department,
    s.s_state,
    d_wr.d_year,
    d_cust_shipto.d_month_seq,
    d_cust_sales.d_year
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
