SELECT
    returning_c.c_customer_id AS returning_customer_id,
    CONCAT(returning_c.c_first_name, ' ', returning_c.c_last_name) AS returning_customer_name,
    refunded_c.c_customer_id AS refunded_customer_id,
    CONCAT(refunded_c.c_first_name, ' ', refunded_c.c_last_name) AS refunded_customer_name,
    d_return.d_date AS return_date,
    wr.wr_return_quantity AS return_quantity,
    wr.wr_return_amt AS return_amount,
    wr.wr_return_tax AS return_tax,
    (wr.wr_return_amt + wr.wr_return_tax) AS total_return_amount,
    wr.wr_net_loss AS net_loss,
    cp.cp_department,
    cp.cp_type,
    cp.cp_description,
    cp.cp_catalog_page_number,
    cp_end.d_date AS catalog_end_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s_closed.d_date AS store_closed_date,
    first_sales_date.d_date AS first_sales_date,
    first_shipto_date.d_date AS first_shipto_date,
    last_review_date.d_date AS last_review_date,
    ROW_NUMBER() OVER (ORDER BY (wr.wr_return_amt + wr.wr_return_tax) DESC) AS return_rank
FROM web_returns wr
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN customer returning_c
    ON wr.wr_returning_customer_sk = returning_c.c_customer_sk
JOIN customer refunded_c
    ON wr.wr_refunded_customer_sk = refunded_c.c_customer_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_return.d_date_sk
JOIN date_dim cp_end
    ON cp.cp_end_date_sk = cp_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
JOIN date_dim s_closed
    ON s.s_closed_date_sk = s_closed.d_date_sk
JOIN date_dim first_sales_date
    ON returning_c.c_first_sales_date_sk = first_sales_date.d_date_sk
JOIN date_dim first_shipto_date
    ON returning_c.c_first_shipto_date_sk = first_shipto_date.d_date_sk
JOIN date_dim last_review_date
    ON returning_c.c_last_review_date = last_review_date.d_date_sk
WHERE cp.cp_department = 'Electronics'
ORDER BY total_return_amount DESC
LIMIT 100
