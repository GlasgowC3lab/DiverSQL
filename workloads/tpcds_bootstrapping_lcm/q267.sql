SELECT
    cc.cc_name,
    cc.cc_market_manager,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    d_ret.d_year AS return_year,
    d_ret.d_month_seq AS return_month,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_refunded_cash) AS total_refunded_cash,
    AVG(sr.sr_fee) AS avg_fee,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    MIN(d_c_first_ship.d_date) AS earliest_ship_date,
    MAX(d_c_last_review.d_date) AS latest_review_date,
    SUM(CASE WHEN cc.cc_tax_percentage > 5.0 THEN sr.sr_return_amt ELSE 0 END) AS high_tax_return_amount
FROM store_returns sr
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
JOIN date_dim d_c_first_ship
    ON c.c_first_shipto_date_sk = d_c_first_ship.d_date_sk
JOIN date_dim d_c_first_sales
    ON c.c_first_sales_date_sk = d_c_first_sales.d_date_sk
JOIN date_dim d_c_last_review
    ON c.c_last_review_date = d_c_last_review.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc
    ON cc.cc_closed_date_sk = d_cc.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
WHERE d_ret.d_year = 2022
  AND cc.cc_country = 'United States'
  AND s.s_state = 'CA'
GROUP BY
    cc.cc_name,
    cc.cc_market_manager,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    d_ret.d_year,
    d_ret.d_month_seq
ORDER BY total_return_amount DESC
LIMIT 100
