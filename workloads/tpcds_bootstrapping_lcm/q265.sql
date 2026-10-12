WITH monthly_store_returns AS (
    SELECT
        d.d_current_month,
        d.d_year,
        s.s_store_name AS s_store_name,
        s.s_city AS s_city,
        s.s_state AS s_state,
        r.r_reason_desc AS r_reason_desc,
        t.t_meal_time AS t_meal_time,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        AVG(wr.wr_return_amt_inc_tax) AS avg_return_amt_inc_tax,
        COUNT(*) AS num_returns,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2019 AND 2022
      AND s.s_state = 'CA'
      AND t.t_am_pm = 'PM'
    GROUP BY
        d.d_current_month,
        d.d_year,
        s.s_store_name,
        s.s_city,
        s.s_state,
        r.r_reason_desc,
        t.t_meal_time
)
SELECT
    d_current_month,
    d_year,
    s_store_name,
    s_city,
    s_state,
    r_reason_desc,
    t_meal_time,
    total_return_amount,
    total_return_quantity,
    avg_return_amt_inc_tax,
    num_returns,
    distinct_orders,
    CASE
        WHEN total_return_amount > 10000 THEN 'HIGH'
        WHEN total_return_amount > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_volume_category,
    ROW_NUMBER() OVER (PARTITION BY d_current_month ORDER BY total_return_amount DESC) AS rank_within_month
FROM monthly_store_returns
WHERE total_return_amount > 0
ORDER BY d_current_month, rank_within_month
LIMIT 200
