SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_date AS sales_date,
    t.t_hour AS sales_hour,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    SUM(ss.ss_quantity) AS total_units_sold,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    SUM(ss.ss_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit_after_returns,
    d_closed.d_date AS store_closed_date
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_returned_time_sk = t.t_time_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d.d_date,
    t.t_hour,
    d_closed.d_date
ORDER BY net_profit_after_returns DESC
LIMIT 100
