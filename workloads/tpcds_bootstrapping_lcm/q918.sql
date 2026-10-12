SELECT
    ca_returning.ca_city AS returning_city,
    ca_refunded.ca_country AS refunded_country,
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_market_manager,
    t.t_meal_time,
    COUNT(DISTINCT wr.wr_order_number) AS num_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_tax
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2022
GROUP BY
    ca_returning.ca_city,
    ca_refunded.ca_country,
    d_ret.d_year,
    d_ret.d_month_seq,
    s.s_market_manager,
    t.t_meal_time
ORDER BY total_return_amount DESC
LIMIT 100
