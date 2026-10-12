SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_manager,
    s.s_store_id,
    s.s_store_name,
    s.s_manager,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month_seq,
    d_ret.d_date AS return_date,
    d_cc_open.d_year AS cc_open_year,
    d_cc_open.d_month_seq AS cc_open_month_seq,
    d_first_ship.d_year AS first_ship_year,
    d_first_sales.d_year AS first_sales_year,
    d_last_review.d_year AS last_review_year,
    COUNT(DISTINCT wr.wr_order_number) AS num_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(rcust.c_birth_year) AS avg_refunded_customer_birth_year,
    COUNT(DISTINCT rcust.c_customer_id) AS num_refunded_customers,
    COUNT(DISTINCT tcust.c_customer_id) AS num_returning_customers
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer rcust
    ON wr.wr_refunded_customer_sk = rcust.c_customer_sk
JOIN customer tcust
    ON wr.wr_returning_customer_sk = tcust.c_customer_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_first_ship
    ON rcust.c_first_shipto_date_sk = d_first_ship.d_date_sk
JOIN date_dim d_first_sales
    ON rcust.c_first_sales_date_sk = d_first_sales.d_date_sk
JOIN date_dim d_last_review
    ON rcust.c_last_review_date = d_last_review.d_date_sk
WHERE d_ret.d_year = 2021
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_manager,
    s.s_store_id,
    s.s_store_name,
    s.s_manager,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_date,
    d_cc_open.d_year,
    d_cc_open.d_month_seq,
    d_first_ship.d_year,
    d_first_sales.d_year,
    d_last_review.d_year
ORDER BY total_net_loss DESC
LIMIT 100
