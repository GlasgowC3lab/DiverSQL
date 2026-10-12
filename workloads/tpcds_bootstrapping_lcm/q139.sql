SELECT
    d_ret.d_year,
    d_ret.d_month_seq,
    cc.cc_division,
    cc.cc_class,
    s.s_state,
    s.s_market_manager,
    c_refunded.c_birth_country,
    CASE WHEN cc.cc_tax_percentage > 5 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END AS tax_category,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer c_refunded
    ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning
    ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    cc.cc_division,
    cc.cc_class,
    s.s_state,
    s.s_market_manager,
    c_refunded.c_birth_country,
    CASE WHEN cc.cc_tax_percentage > 5 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
