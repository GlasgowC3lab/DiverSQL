SELECT
    s.s_store_id,
    MAX(s.s_store_name) AS store_name,
    ds.d_year            AS store_closed_year,
    dr.d_year            AS store_return_year,
    SUM(sr.sr_net_loss)                 AS total_store_return_loss,
    SUM(wr.wr_net_loss)                 AS total_web_return_loss,
    SUM(ws.ws_net_profit)               AS total_web_sales_profit,
    SUM(ws.ws_quantity)                 AS total_web_sales_quantity,
    SUM(sr.sr_return_quantity)          AS total_store_return_quantity,
    SUM(wr.wr_return_quantity)          AS total_web_return_quantity,
    COUNT(DISTINCT ws.ws_order_number)  AS distinct_web_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_return_tickets,
    COUNT(DISTINCT wr.wr_order_number)  AS distinct_web_return_orders,
    CASE
        WHEN SUM(sr.sr_net_loss) = 0 THEN NULL
        ELSE ROUND(SUM(ws.ws_net_profit) / SUM(sr.sr_net_loss), 2)
    END AS profit_to_store_return_loss_ratio
FROM store s
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
JOIN date_dim dr
    ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN date_dim ds
    ON s.s_closed_date_sk = ds.d_date_sk
CROSS JOIN web_sales ws
JOIN date_dim dsold
    ON ws.ws_sold_date_sk = dsold.d_date_sk
JOIN date_dim dship
    ON ws.ws_ship_date_sk = dship.d_date_sk
JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
JOIN date_dim drwr
    ON wr.wr_returned_date_sk = drwr.d_date_sk
GROUP BY ROLLUP (s.s_store_id, ds.d_year, dr.d_year)
ORDER BY total_web_sales_profit DESC
LIMIT 100
