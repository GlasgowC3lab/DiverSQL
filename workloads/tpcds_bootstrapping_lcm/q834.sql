SELECT
    d_sales.d_year AS sales_year,
    d_sales.d_month_seq AS sales_month_seq,
    d_sales.d_week_seq AS sales_week_seq,
    s.s_state AS store_state,
    s.s_city AS store_city,
    s.s_store_name AS store_name,
    d_closed.d_current_year AS store_closed_year,
    d_ship.d_month_seq AS ship_month_seq,
    d_return.d_day_name AS return_day_name,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ss.ss_ext_discount_amt) AS total_store_discount,
    SUM(ss.ss_net_profit) AS total_store_profit,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ws.ws_ext_discount_amt) AS total_web_discount,
    SUM(ws.ws_net_profit) AS total_web_profit,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_tax) AS total_return_tax,
    SUM(wr.wr_net_loss) AS total_return_net_loss,
    (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(wr.wr_net_loss)) AS net_profit_after_returns
FROM store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    d_sales.d_week_seq,
    s.s_state,
    s.s_city,
    s.s_store_name,
    d_closed.d_current_year,
    d_ship.d_month_seq,
    d_return.d_day_name
ORDER BY net_profit_after_returns DESC
LIMIT 100
