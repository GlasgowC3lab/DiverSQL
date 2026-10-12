SELECT
    cc.cc_division_name,
    cc.cc_market_manager,
    s.s_division_name,
    s.s_market_manager,
    d_ret.d_quarter_name AS return_quarter,
    d_cc_open.d_year AS cc_open_year,
    d_store_closed.d_year AS store_closed_year,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(cd.cd_credit_rating) AS max_credit_rating,
    MIN(d_ret.d_date) AS earliest_return_date
FROM store_returns sr
JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
GROUP BY
    cc.cc_division_name,
    cc.cc_market_manager,
    s.s_division_name,
    s.s_market_manager,
    d_ret.d_quarter_name,
    d_cc_open.d_year,
    d_store_closed.d_year
ORDER BY total_net_loss DESC
LIMIT 100
