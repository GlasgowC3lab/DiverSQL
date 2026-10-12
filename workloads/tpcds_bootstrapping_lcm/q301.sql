SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city AS store_city,
    d_ret.d_date AS closed_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_day_name,
    r.r_reason_desc,
    ca_returning.ca_city AS returning_city,
    ca_returning.ca_state AS returning_state,
    ca_refunded.ca_city AS refunded_city,
    ca_refunded.ca_state AS refunded_state,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_tax,
    ROUND(AVG(wr.wr_net_loss), 2) AS avg_net_loss
FROM web_returns wr
INNER JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
INNER JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
INNER JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
INNER JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
INNER JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2023
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    d_ret.d_date,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_day_name,
    r.r_reason_desc,
    ca_returning.ca_city,
    ca_returning.ca_state,
    ca_refunded.ca_city,
    ca_refunded.ca_state
HAVING SUM(wr.wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
