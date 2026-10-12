SELECT
    cc.cc_city,
    cc.cc_state,
    s.s_city AS store_city,
    s.s_state AS store_state,
    d_ret.d_year,
    d_ret.d_month_seq,
    COUNT(*) AS return_count,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(c.c_birth_year) AS avg_customer_birth_year,
    MIN(d_cust_ship.d_date) AS first_ship_to_date,
    MIN(d_cust_sales.d_date) AS first_sales_date,
    MIN(d_cc_open.d_date) AS call_center_open_date,
    MAX(d_cc_closed.d_date) AS call_center_closed_date,
    MAX(ds_closed.d_date) AS store_closed_date
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim ds_closed
    ON s.s_closed_date_sk = ds_closed.d_date_sk
JOIN customer c
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN date_dim d_cust_ship
    ON c.c_first_shipto_date_sk = d_cust_ship.d_date_sk
JOIN date_dim d_cust_sales
    ON c.c_first_sales_date_sk = d_cust_sales.d_date_sk
WHERE cc.cc_country = 'United States'
  AND d_ret.d_year = 2002
GROUP BY
    cc.cc_city,
    cc.cc_state,
    s.s_city,
    s.s_state,
    d_ret.d_year,
    d_ret.d_month_seq
ORDER BY total_net_loss DESC
LIMIT 100
