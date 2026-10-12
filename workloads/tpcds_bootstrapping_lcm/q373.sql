SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_type,
    d_cp_start.d_date AS catalog_start_date,
    d_ret.d_date AS catalog_end_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    s.s_floor_space,
    s.s_number_employees,
    s.s_floor_space / NULLIF(s.s_number_employees, 0) AS floor_space_per_employee,
    d_ret.d_year AS store_closed_year,
    wr.wr_order_number,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_return_tax,
    wr.wr_fee,
    wr.wr_net_loss,
    (wr.wr_return_amt - wr.wr_return_tax + wr.wr_fee) AS net_return_value,
    CASE
        WHEN wr.wr_return_amt > 200 THEN 'HIGH'
        WHEN wr.wr_return_amt > 50 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_amount_category,
    ca_return.ca_city AS returning_city,
    ca_return.ca_state AS returning_state,
    ca_return.ca_country AS returning_country,
    ca_refund.ca_city AS refunded_city,
    ca_refund.ca_state AS refunded_state,
    ca_refund.ca_country AS refunded_country,
    d_ret.d_day_name AS return_day_name,
    d_ret.d_holiday AS return_holiday,
    date_diff('day', d_cp_start.d_date, d_ret.d_date) AS days_between_catalog_start_and_return
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN customer_address ca_return
    ON wr.wr_returning_addr_sk = ca_return.ca_address_sk
JOIN customer_address ca_refund
    ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d_ret.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
WHERE cp.cp_type = 'PROMO'
  AND s.s_state = 'CA'
  AND ca_return.ca_country = 'United States'
ORDER BY wr.wr_returned_date_sk DESC
LIMIT 100
