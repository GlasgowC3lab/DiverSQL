SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month,
    ca_bill.ca_city AS bill_city,
    ca_ship.ca_city AS ship_city,
    ca_ret.ca_city AS return_city,
    ca_ref.ca_city AS refunded_city,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_net_profit,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_net_loss,
    (ws.ws_net_profit - COALESCE(wr.wr_net_loss, 0)) AS net_profit_after_returns,
    ROW_NUMBER() OVER (
        PARTITION BY s.s_store_id
        ORDER BY (ws.ws_net_profit - COALESCE(wr.wr_net_loss, 0)) DESC
    ) AS profit_rank
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN customer_address ca_ret
    ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
JOIN customer_address ca_ref
    ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
WHERE ws.ws_net_profit > 0
ORDER BY net_profit_after_returns DESC
LIMIT 100
