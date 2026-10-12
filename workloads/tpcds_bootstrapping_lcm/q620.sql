SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    CASE
        WHEN d.d_month_seq <= 6 THEN 'H1'
        ELSE 'H2'
    END AS half_year,
    CASE
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN t.t_hour BETWEEN 18 AND 23 THEN 'Evening'
        ELSE 'Night'
    END AS day_part,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN d.d_holiday = 'Y' THEN wr.wr_return_amt ELSE 0 END) AS holiday_return_amount,
    SUM(CASE WHEN d.d_weekend = 'Y' THEN wr.wr_return_amt ELSE 0 END) AS weekend_return_amount,
    SUM(CASE WHEN t.t_meal_time = 'Breakfast' THEN wr.wr_return_amt ELSE 0 END) AS breakfast_return_amount,
    COUNT(*) FILTER (WHERE wr.wr_fee > 0) AS fee_return_count,
    AVG(wr.wr_fee) AS avg_fee
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2021 AND 2023
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    CASE
        WHEN d.d_month_seq <= 6 THEN 'H1'
        ELSE 'H2'
    END,
    CASE
        WHEN t.t_hour BETWEEN 6 AND 11 THEN 'Morning'
        WHEN t.t_hour BETWEEN 12 AND 17 THEN 'Afternoon'
        WHEN t.t_hour BETWEEN 18 AND 23 THEN 'Evening'
        ELSE 'Night'
    END
HAVING SUM(wr.wr_return_amt) > 500
ORDER BY total_return_amount DESC
LIMIT 100
