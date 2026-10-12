SELECT
    cc.cc_manager,
    s.s_manager,
    d_ret.d_year AS return_year,
    d_open.d_year AS cc_open_year,
    d_ret.d_month_seq AS return_month_seq,
    CASE
        WHEN ca_return.ca_state = ca_refund.ca_state THEN 'Same State'
        ELSE 'Different State'
    END AS address_state_relation,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_fee) AS avg_fee,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_return_amt_inc_tax) - SUM(wr.wr_return_amt) AS total_tax_amount,
    ROUND(AVG(wr.wr_return_quantity), 2) AS avg_return_quantity
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer_address ca_refund
    ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_return
    ON wr.wr_returning_addr_sk = ca_return.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
WHERE d_ret.d_year BETWEEN 2015 AND 2020
  AND s.s_state = ca_return.ca_state
GROUP BY
    cc.cc_manager,
    s.s_manager,
    d_ret.d_year,
    d_open.d_year,
    d_ret.d_month_seq,
    CASE
        WHEN ca_return.ca_state = ca_refund.ca_state THEN 'Same State'
        ELSE 'Different State'
    END
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC
LIMIT 200
