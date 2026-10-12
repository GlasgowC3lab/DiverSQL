SELECT
    cp.cp_department,
    s.s_state,
    CONCAT(cp.cp_department, '-', s.s_state) AS dept_state,
    d_start.d_year AS start_year,
    d_end.d_year AS end_year,
    COUNT(DISTINCT wr.wr_order_number) AS num_orders,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(date_diff('day', d_start.d_date, d_return.d_date)) AS avg_days_start_to_return,
    SUM(CASE WHEN ra.ca_state = 'CA' THEN 1 ELSE 0 END) AS returns_from_ca,
    SUM(CASE WHEN fa.ca_country = 'United States' THEN 1 ELSE 0 END) AS returns_refunded_us,
    MAX(d_return.d_date) AS latest_return_date,
    COUNT(*) FILTER (WHERE d_return.d_day_name = 'Saturday') AS saturday_returns
FROM web_returns wr
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
CROSS JOIN catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN customer_address ra
    ON wr.wr_returning_addr_sk = ra.ca_address_sk
JOIN customer_address fa
    ON wr.wr_refunded_addr_sk = fa.ca_address_sk
WHERE d_return.d_date BETWEEN d_start.d_date AND d_end.d_date
GROUP BY
    cp.cp_department,
    s.s_state,
    CONCAT(cp.cp_department, '-', s.s_state),
    d_start.d_year,
    d_end.d_year
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
