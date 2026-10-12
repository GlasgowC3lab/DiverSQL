SELECT
    d.d_year AS year,
    d.d_quarter_seq AS quarter,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    COUNT(DISTINCT ws.ws_order_number) AS web_sales_orders,
    SUM(ws.ws_quantity) AS total_web_sales_quantity,
    SUM(ws.ws_ext_sales_price) AS total_web_sales_ext_price,
    SUM(ws.ws_net_profit) AS total_web_sales_net_profit,
    SUM(wr.wr_return_quantity) AS total_web_returns_quantity,
    SUM(wr.wr_return_amt) AS total_web_returns_amount,
    SUM(wr.wr_net_loss) AS total_web_returns_net_loss,
    SUM(sr.sr_return_quantity) AS total_store_returns_quantity,
    SUM(sr.sr_return_amt) AS total_store_returns_amount,
    SUM(sr.sr_net_loss) AS total_store_returns_net_loss,
    (SUM(ws.ws_ext_sales_price) - SUM(wr.wr_return_amt) - SUM(sr.sr_return_amt)) AS net_sales_after_returns,
    (SUM(ws.ws_net_profit) - SUM(wr.wr_net_loss) - SUM(sr.sr_net_loss)) AS net_profit_after_returns,
    CASE
        WHEN SUM(ws.ws_ext_sales_price) > 0 THEN
            (SUM(wr.wr_return_amt) + SUM(sr.sr_return_amt)) / SUM(ws.ws_ext_sales_price)
        ELSE NULL
    END AS return_rate
FROM date_dim d
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
   AND sr.sr_returned_date_sk = d.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
   AND ws.ws_ship_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
GROUP BY
    d.d_year,
    d.d_quarter_seq,
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state
ORDER BY
    d.d_year,
    d.d_quarter_seq,
    s.s_store_id
