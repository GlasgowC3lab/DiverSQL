SELECT
    wr.wr_returned_date_sk,
    ws.ws_sold_date_sk,
    wr.wr_return_quantity,
    ws.ws_quantity,
    (wr.wr_return_amt * 1.1) AS adjusted_return_amt,
    (ws.ws_ext_sales_price - ws.ws_ext_discount_amt) AS net_sales_price,
    CASE
        WHEN wr.wr_return_quantity > ws.ws_quantity THEN 'Return exceeds sale'
        WHEN wr.wr_return_quantity = ws.ws_quantity THEN 'Return equals sale'
        ELSE 'Partial return'
    END AS return_status,
    CASE
        WHEN ws.ws_net_profit > 0 THEN 'Profit'
        WHEN ws.ws_net_profit = 0 THEN 'Break-even'
        ELSE 'Loss'
    END AS profit_indicator,
    (wr.wr_return_amt + ws.ws_ext_tax) AS total_amount
FROM web_returns wr
JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
WHERE wr.wr_returned_date_sk = 2451758
  AND ws.ws_sold_date_sk = 2451945
