SELECT
    d_sold.d_date AS sales_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    s.s_city,
    t_sold.t_shift AS sales_shift,
    t_return.t_meal_time AS return_meal_time,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    SUM(cs.cs_quantity) AS total_units_sold,
    SUM(cs.cs_net_profit) AS total_sales_net_profit,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
    SUM(cs.cs_net_paid) - COALESCE(SUM(wr.wr_return_amt), 0) AS net_paid_after_returns,
    CASE
        WHEN SUM(cs.cs_net_paid) = 0 THEN 0
        ELSE ROUND((COALESCE(SUM(wr.wr_return_amt), 0) / SUM(cs.cs_net_paid)) * 100, 2)
    END AS return_rate_percent,
    ROW_NUMBER() OVER (PARTITION BY d_sold.d_date ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank_by_store_day
FROM catalog_sales cs
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ship.d_date_sk
    AND wr.wr_returned_time_sk = t_sold.t_time_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_return
    ON wr.wr_returned_time_sk = t_return.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    d_sold.d_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    s.s_city,
    t_sold.t_shift,
    t_return.t_meal_time
ORDER BY total_sales_net_paid DESC
LIMIT 100
