SELECT
    d_sold.d_year,
    d_sold.d_quarter_seq,
    t_sold.t_hour,
    d_sold.d_holiday,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    CASE WHEN SUM(ws.ws_net_profit) = 0 THEN 0
         ELSE SUM(COALESCE(wr.wr_net_loss, 0)) / SUM(ws.ws_net_profit)
    END AS return_loss_ratio
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_seq,
    t_sold.t_hour,
    d_sold.d_holiday
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY
    d_sold.d_year,
    d_sold.d_quarter_seq,
    t_sold.t_hour,
    d_sold.d_holiday
