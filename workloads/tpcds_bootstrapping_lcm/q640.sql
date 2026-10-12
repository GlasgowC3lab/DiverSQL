SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    t.t_hour,
    t.t_minute,
    s.s_store_id,
    s.s_state,
    s.s_city,
    s.s_number_employees,
    hd_ret.hd_dep_count AS returning_dep_count,
    hd_ret.hd_vehicle_count AS returning_vehicle_count,
    hd_ref.hd_dep_count AS refunded_dep_count,
    hd_ref.hd_vehicle_count AS refunded_vehicle_count,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS return_count
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN household_demographics hd_ref
    ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
JOIN household_demographics hd_ret
    ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
    d.d_date,
    d.d_year,
    d.d_month_seq,
    d.d_day_name,
    t.t_hour,
    t.t_minute,
    s.s_store_id,
    s.s_state,
    s.s_city,
    s.s_number_employees,
    hd_ret.hd_dep_count,
    hd_ret.hd_vehicle_count,
    hd_ref.hd_dep_count,
    hd_ref.hd_vehicle_count
ORDER BY total_return_amount DESC
LIMIT 100
