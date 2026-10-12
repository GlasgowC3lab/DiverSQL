SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_quarter_seq AS sold_quarter,
    s.s_store_name,
    w.w_warehouse_name,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(wr.wr_return_quantity), 0) AS total_return_quantity,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    SUM(ws.ws_ext_sales_price) - COALESCE(SUM(wr.wr_return_amt), 0) AS net_sales_after_returns,
    SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit_after_returns,
    AVG(ws.ws_quantity) AS avg_quantity_per_order,
    CASE
        WHEN SUM(ws.ws_ext_sales_price) = 0 THEN NULL
        ELSE (SUM(ws.ws_net_profit) / SUM(ws.ws_ext_sales_price)) * 100
    END AS profit_margin_percent
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns wr
    ON ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_order_number = wr.wr_order_number
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_store
    ON ws.ws_sold_date_sk = d_store.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_store.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_seq,
    s.s_store_name,
    w.w_warehouse_name
HAVING SUM(ws.ws_ext_sales_price) > 5000
ORDER BY
    d_sold.d_year,
    d_sold.d_quarter_seq,
    s.s_store_name
