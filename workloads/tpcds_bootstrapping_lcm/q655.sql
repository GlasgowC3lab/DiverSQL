SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    cp.cp_catalog_page_number,
    cp.cp_department,
    dim_ret.d_year AS return_year,
    dim_ret.d_month_seq AS return_month,
    dim_start.d_year AS catalog_start_year,
    dim_start.d_month_seq AS catalog_start_month,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS num_returns,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    MIN(dim_sales_ref.d_year) AS min_refunded_first_sales_year,
    MAX(dim_sales_ret.d_year) AS max_returning_first_sales_year,
    date_diff('day', dim_start.d_date, dim_ret.d_date) AS days_between_start_and_return
FROM web_returns wr
JOIN date_dim dim_ret
    ON wr.wr_returned_date_sk = dim_ret.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = dim_ret.d_date_sk
JOIN date_dim dim_start
    ON cp.cp_start_date_sk = dim_start.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = dim_ret.d_date_sk
JOIN customer cust_ref
    ON wr.wr_refunded_customer_sk = cust_ref.c_customer_sk
JOIN date_dim dim_sales_ref
    ON cust_ref.c_first_sales_date_sk = dim_sales_ref.d_date_sk
JOIN date_dim dim_shipto_ref
    ON cust_ref.c_first_shipto_date_sk = dim_shipto_ref.d_date_sk
JOIN customer cust_ret
    ON wr.wr_returning_customer_sk = cust_ret.c_customer_sk
JOIN date_dim dim_sales_ret
    ON cust_ret.c_first_sales_date_sk = dim_sales_ret.d_date_sk
JOIN date_dim dim_shipto_ret
    ON cust_ret.c_first_shipto_date_sk = dim_shipto_ret.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    cp.cp_catalog_page_number,
    cp.cp_department,
    dim_ret.d_year,
    dim_ret.d_month_seq,
    dim_start.d_year,
    dim_start.d_month_seq,
    date_diff('day', dim_start.d_date, dim_ret.d_date)
ORDER BY total_net_loss DESC
LIMIT 100
