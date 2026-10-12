SELECT
    (d_sold.d_year * 100 + d_sold.d_month_seq) AS year_month,
    i.i_category,
    i.i_brand,
    s.s_state,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_ext_wholesale_cost) AS total_wholesale_cost,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COALESCE(SUM(wr.wr_return_quantity), 0) AS total_return_qty,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
    CAST(COALESCE(SUM(wr.wr_return_quantity), 0) AS DOUBLE) / NULLIF(SUM(ws.ws_quantity), 0) AS return_rate,
    (SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_return_amt), 0)) AS net_profit_after_returns,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amount,
    MIN(d_return.d_date) AS first_return_date,
    MAX(d_ship.d_date) AS last_ship_date
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    (d_sold.d_year * 100 + d_sold.d_month_seq),
    i.i_category,
    i.i_brand,
    s.s_state
HAVING SUM(ws.ws_ext_sales_price) > 5000
ORDER BY total_sales_amount DESC
LIMIT 100
