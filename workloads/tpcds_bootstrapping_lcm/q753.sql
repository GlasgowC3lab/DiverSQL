SELECT
    cc.cc_name AS call_center_name,
    cc.cc_manager AS call_center_manager,
    s.s_store_name AS store_name,
    s.s_market_desc AS store_market_desc,
    d_ret.d_year AS return_year,
    d_ret.d_moy AS return_month,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_fee) AS avg_fee,
    SUM(sr.sr_return_amt_inc_tax) - SUM(sr.sr_return_tax) AS net_return_without_tax,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    MIN(d_ret.d_date) AS first_return_date,
    MAX(d_ret.d_date) AS last_return_date,
    CASE
        WHEN SUM(sr.sr_return_amt) > 10000 THEN 'Very High'
        WHEN SUM(sr.sr_return_amt) > 5000 THEN 'High'
        ELSE 'Normal'
    END AS return_category,
    DATE_DIFF('day', MIN(d_cc_open.d_date), MIN(d_store_closed.d_date)) AS cc_open_to_store_closed_days,
    DATE_DIFF('day', MIN(d_store_closed.d_date), MIN(d_ret.d_date)) AS days_between_store_closed_and_return,
    DATE_DIFF('day', MIN(d_c_first_sales.d_date), MIN(d_c_first_shipto.d_date)) AS days_between_first_sale_and_ship,
    DATE_DIFF('day', MIN(d_c_first_sales.d_date), MIN(d_c_last_review.d_date)) AS days_between_first_sale_and_review
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN date_dim d_c_first_shipto
    ON c.c_first_shipto_date_sk = d_c_first_shipto.d_date_sk
JOIN date_dim d_c_first_sales
    ON c.c_first_sales_date_sk = d_c_first_sales.d_date_sk
JOIN date_dim d_c_last_review
    ON c.c_last_review_date = d_c_last_review.d_date_sk
GROUP BY
    cc.cc_name,
    cc.cc_manager,
    s.s_store_name,
    s.s_market_desc,
    d_ret.d_year,
    d_ret.d_moy
HAVING
    SUM(sr.sr_return_amt) > 0
ORDER BY total_return_amount DESC
LIMIT 100
