SELECT
    cc.cc_name AS call_center_name,
    cc.cc_city AS call_center_city,
    cc.cc_state AS call_center_state,
    s.s_store_name AS store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_return.d_year AS return_year,
    d_return.d_moy AS return_month,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS total_returns,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT cust_returning.c_customer_sk) AS distinct_returning_customers,
    COUNT(DISTINCT cust_refunded.c_customer_sk) AS distinct_refunded_customers,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    AVG(cc.cc_tax_percentage) AS avg_call_center_tax_percentage,
    AVG(s.s_tax_percentage) AS avg_store_tax_percentage,
    MIN(d_c_first_sales.d_date) AS earliest_customer_first_sales_date,
    MAX(d_c_first_shipto.d_date) AS latest_customer_first_shipto_date,
    AVG(DATE_DIFF('day', d_c_first_sales.d_date, d_return.d_date)) AS avg_days_between_first_sales_and_return,
    MIN(d_cc_open.d_date) AS call_center_open_date,
    MAX(d_cc_closed.d_date) AS call_center_closed_date
FROM catalog_returns cr
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN customer cust_refunded
    ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
JOIN customer cust_returning
    ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
JOIN date_dim d_c_first_shipto
    ON cust_returning.c_first_shipto_date_sk = d_c_first_shipto.d_date_sk
JOIN date_dim d_c_first_sales
    ON cust_returning.c_first_sales_date_sk = d_c_first_sales.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
GROUP BY
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_return.d_year,
    d_return.d_moy
ORDER BY total_net_loss DESC
LIMIT 100
