SELECT
    cc.cc_division_name,
    s.s_state,
    d_wr.d_year,
    d_wr.d_month_seq,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS total_returns,
    COUNT(DISTINCT c.c_customer_id) AS distinct_refunded_customers,
    COUNT(DISTINCT rc.c_customer_id) AS distinct_returning_customers,
    SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customer_returns,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    ROUND(SUM(wr.wr_return_amt) / NULLIF(SUM(wr.wr_return_quantity), 0), 2) AS avg_amount_per_item,
    SUM(wr.wr_return_tax) AS total_return_tax,
    (SUM(wr.wr_return_amt) - SUM(wr.wr_return_tax)) AS net_return_excluding_tax,
    d_c_shipto.d_year AS shipto_year,
    d_c_shipto.d_month_seq AS shipto_month,
    SUM(wr.wr_net_loss) / NULLIF(COUNT(*), 0) AS avg_net_loss_per_return
FROM web_returns wr
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN customer rc ON wr.wr_returning_customer_sk = rc.c_customer_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_wr.d_date_sk
JOIN date_dim d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_wr.d_date_sk
JOIN date_dim d_c_shipto ON c.c_first_shipto_date_sk = d_c_shipto.d_date_sk
WHERE d_wr.d_year BETWEEN 2000 AND 2005
  AND cc.cc_division IS NOT NULL
  AND s.s_state IS NOT NULL
GROUP BY
    cc.cc_division_name,
    s.s_state,
    d_wr.d_year,
    d_wr.d_month_seq,
    d_c_shipto.d_year,
    d_c_shipto.d_month_seq
HAVING SUM(wr.wr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
