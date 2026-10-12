SELECT
    s.s_store_id,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_paid) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_quantity_returned,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_ship_delay_days
FROM date_dim d_sold
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2020
GROUP BY s.s_store_id, s.s_state, d_sold.d_year, d_sold.d_month_seq
ORDER BY total_sales DESC
LIMIT 100
