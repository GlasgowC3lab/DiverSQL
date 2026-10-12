SELECT
    d_ret.d_year AS return_year,
    d_ret.d_moy AS return_month,
    d_cust.d_year AS first_shipto_year,
    CASE WHEN d_ret.d_moy % 2 = 0 THEN 'Even' ELSE 'Odd' END AS month_parity,
    cc.cc_division_name,
    s.s_division_name,
    cc.cc_market_manager,
    AVG(cc.cc_gmt_offset) AS avg_cc_gmt_offset,
    AVG(cc.cc_tax_percentage) AS avg_cc_tax_percentage,
    AVG(s.s_tax_percentage) AS avg_store_tax_percentage,
    COUNT(DISTINCT c_refunded.c_customer_id) AS distinct_refunded_customers,
    COUNT(DISTINCT c_returning.c_customer_id) AS distinct_returning_customers,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(CASE WHEN wr.wr_return_amt > 100 THEN wr.wr_net_loss ELSE 0 END) AS net_loss_over_100,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    CASE
        WHEN SUM(wr.wr_return_amt) > 10000 THEN 'High'
        WHEN SUM(wr.wr_return_amt) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS return_amount_category
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN customer c_refunded
    ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning
    ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
JOIN date_dim d_cust
    ON c_returning.c_first_shipto_date_sk = d_cust.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_moy,
    d_cust.d_year,
    CASE WHEN d_ret.d_moy % 2 = 0 THEN 'Even' ELSE 'Odd' END,
    cc.cc_division_name,
    s.s_division_name,
    cc.cc_market_manager
ORDER BY total_net_loss DESC
LIMIT 100
