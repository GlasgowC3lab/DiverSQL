SELECT ws.ws_order_number,
       ws.ws_quantity,
       wr.wr_return_quantity,
       ws.ws_ext_sales_price,
       wr.wr_return_amt,
       (ws.ws_ext_sales_price - wr.wr_return_amt) AS net_sales_diff,
       CASE WHEN ws.ws_quantity > 0 THEN ws.ws_ext_sales_price / ws.ws_quantity ELSE 0 END AS avg_price_per_item,
       CASE WHEN wr.wr_return_quantity > 0 THEN wr.wr_return_amt / wr.wr_return_quantity ELSE 0 END AS avg_return_amt_per_item,
       CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' WHEN ws.ws_net_profit = 0 THEN 'Break-even' ELSE 'Loss' END AS profit_category,
       (ws.ws_ext_sales_price * 0.1) + (wr.wr_return_amt * 0.05) AS combined_fee_estimate
FROM web_sales ws
JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk AND ws.ws_order_number = wr.wr_order_number
WHERE ws.ws_sold_date_sk = 2451328 AND wr.wr_returned_date_sk = 2452928
