SELECT
    cc.cc_company_name,
    cc.cc_market_manager,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    d_ret.d_year,
    d_ret.d_month_seq,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_quantity) AS avg_return_qty,
    SUM(CASE WHEN ca.ca_state = s.s_state THEN sr.sr_return_amt ELSE 0 END) AS same_state_return_amount,
    SUM(CASE WHEN d_ret.d_dow IN (1,7) THEN sr.sr_return_amt ELSE 0 END) AS weekend_return_amount,
    SUM(CASE WHEN d_ret.d_current_quarter = 'Q1' THEN sr.sr_return_amt ELSE 0 END) AS q1_return_amount,
    SUM(CASE WHEN d_ret.d_date BETWEEN d_cc_open.d_date AND d_store_closed.d_date THEN sr.sr_return_amt ELSE 0 END) AS return_during_cc_open_period
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_ret.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
    cc.cc_company_name,
    cc.cc_market_manager,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    d_ret.d_year,
    d_ret.d_month_seq
HAVING SUM(sr.sr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
