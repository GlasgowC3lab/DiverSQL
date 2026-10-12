SELECT
    d_closed.d_year AS closing_year,
    d_open.d_year AS opening_year,
    cc.cc_division_name,
    s.s_state,
    COUNT(DISTINCT wr.wr_order_number) AS num_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_tax) AS avg_return_tax,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(cc.cc_employees) AS total_cc_employees,
    SUM(s.s_number_employees) AS total_store_employees,
    (SUM(wr.wr_return_amt) / NULLIF(SUM(s.s_floor_space), 0)) AS return_per_sqft,
    DATE_DIFF('day', d_open.d_date, d_closed.d_date) AS days_open_to_close
FROM call_center cc
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_closed.d_date_sk
WHERE d_closed.d_year BETWEEN 2000 AND 2022
  AND cc.cc_employees > 0
GROUP BY
    d_closed.d_year,
    d_open.d_year,
    cc.cc_division_name,
    s.s_state,
    DATE_DIFF('day', d_open.d_date, d_closed.d_date)
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
