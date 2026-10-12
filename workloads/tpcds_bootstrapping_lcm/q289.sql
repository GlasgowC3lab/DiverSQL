SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    d_return.d_date AS return_date,
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_description,
    s.s_store_id,
    s.s_store_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT wr.wr_returned_date_sk) AS num_return_dates
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2020
GROUP BY
    ws.ws_order_number,
    ws.ws_item_sk,
    d_sold.d_date,
    d_ship.d_date,
    d_return.d_date,
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_description,
    s.s_store_id,
    s.s_store_name
ORDER BY total_sales DESC
LIMIT 100
