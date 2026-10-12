SELECT
    s.s_store_id,
    s.s_city AS store_city,
    s.s_state AS store_state,
    s.s_market_id,
    d.d_date,
    d.d_day_name,
    d.d_holiday,
    t.t_hour,
    t.t_meal_time,
    t.t_am_pm,
    ca_ref.ca_city AS refunded_city,
    ca_ref.ca_state AS refunded_state,
    ca_ret.ca_city AS returning_city,
    ca_ret.ca_state AS returning_state,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_tax) AS total_tax,
    SUM(wr.wr_return_ship_cost) AS total_ship_cost,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    (SUM(wr.wr_return_amt_inc_tax)
        - SUM(wr.wr_return_ship_cost)
        - SUM(wr.wr_return_tax)
        - SUM(wr.wr_fee)
        - SUM(wr.wr_reversed_charge)) AS net_profit,
    CASE
        WHEN ca_ref.ca_location_type = 'RESIDENTIAL' THEN 'Residential'
        WHEN ca_ref.ca_location_type = 'BUSINESS' THEN 'Business'
        ELSE 'Other'
    END AS refunded_address_type
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN customer_address ca_ref
    ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret
    ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    s.s_market_id,
    d.d_date,
    d.d_day_name,
    d.d_holiday,
    t.t_hour,
    t.t_meal_time,
    t.t_am_pm,
    ca_ref.ca_city,
    ca_ref.ca_state,
    ca_ret.ca_city,
    ca_ret.ca_state,
    ca_ref.ca_location_type
ORDER BY total_return_amount DESC
LIMIT 100
