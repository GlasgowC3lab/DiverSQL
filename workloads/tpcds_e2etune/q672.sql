SELECT ship_mode,
       sold_date_sk,
       total_net_profit,
       total_return_amount,
       total_net_loss,
       avg_discount,
       RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM (
    SELECT ws.ws_ship_mode_sk AS ship_mode,
           ws.ws_sold_date_sk AS sold_date_sk,
           SUM(ws.ws_net_profit) AS total_net_profit,
           SUM(wr.wr_return_amt) AS total_return_amount,
           SUM(wr.wr_net_loss) AS total_net_loss,
           AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN web_returns wr
      ON ws.ws_item_sk = wr.wr_item_sk
     AND ws.ws_order_number = wr.wr_order_number
    WHERE ws.ws_sold_date_sk BETWEEN 2451910 AND 2452000
      AND wr.wr_returned_date_sk BETWEEN 2451910 AND 2452000
    GROUP BY ws.ws_ship_mode_sk, ws.ws_sold_date_sk
    HAVING SUM(ws.ws_net_profit) > 0
) t
ORDER BY total_net_loss DESC
LIMIT 100
