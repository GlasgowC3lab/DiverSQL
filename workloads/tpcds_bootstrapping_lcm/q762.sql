SELECT
    d.d_year,
    s.s_state,
    t_sales.t_hour AS sales_hour,
    MIN(t_ret.t_hour) AS first_return_hour,
    SUM(ws.ws_net_paid) AS total_sales,
    SUM(ws.ws_ext_sales_price) AS total_ext_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_return_amt, 0)) / NULLIF(SUM(ws.ws_net_paid), 0) AS return_rate,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    COUNT(DISTINCT wr.wr_order_number) AS return_order_count,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_qty,
    SUM(ws.ws_quantity) - SUM(COALESCE(wr.wr_return_quantity, 0)) AS net_quantity,
    (SUM(ws.ws_net_paid) - SUM(COALESCE(wr.wr_return_amt, 0))) AS net_revenue,
    SUM(CASE WHEN t_ret.t_hour IS NOT NULL AND t_ret.t_hour = t_sales.t_hour THEN 1 ELSE 0 END) AS same_hour_return_count
FROM web_sales ws
JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t_sales
    ON ws.ws_sold_time_sk = t_sales.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN time_dim t_ret
    ON wr.wr_returned_time_sk = t_ret.t_time_sk
GROUP BY
    d.d_year,
    s.s_state,
    t_sales.t_hour
HAVING SUM(ws.ws_net_paid) > 10000
ORDER BY net_revenue DESC
LIMIT 100
