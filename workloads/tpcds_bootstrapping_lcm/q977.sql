SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_current_month,
    d_sold.d_week_seq,
    t_sold.t_hour AS sales_hour,
    t_sold.t_am_pm AS sales_am_pm,
    d_ship.d_current_month AS ship_month,
    d_return.d_year AS return_year,
    t_return.t_hour AS return_hour,
    d_store_closed.d_date AS store_closed_date,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_profit) AS total_sales_net_profit,
    SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amount,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
    CASE 
        WHEN SUM(ws.ws_quantity) > 0 
        THEN SUM(COALESCE(wr.wr_return_quantity, 0)) / SUM(ws.ws_quantity)
        ELSE 0
    END AS return_rate,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
LEFT JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
LEFT JOIN web_returns wr
    ON ws.ws_item_sk = wr.wr_item_sk
    AND ws.ws_order_number = wr.wr_order_number
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN time_dim t_return
    ON wr.wr_returned_time_sk = t_return.t_time_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
LEFT JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_current_month,
    d_sold.d_week_seq,
    t_sold.t_hour,
    t_sold.t_am_pm,
    d_ship.d_current_month,
    d_return.d_year,
    t_return.t_hour,
    d_store_closed.d_date
ORDER BY total_sales_amount DESC
LIMIT 100
