SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_tax_percentage,
    d_store.d_year AS store_close_year,
    d_return.d_year AS return_year,
    ca_bill.ca_country AS billing_country,
    ca_ship.ca_state AS shipping_state,
    ca_returning.ca_city AS returning_city,
    ca_refunded.ca_zip AS refunded_zip,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    SUM(ws.ws_net_paid) AS total_sales_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_ext_sales_price,
    SUM(ws.ws_net_profit) AS total_sales_profit,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_return_loss,
    (SUM(ws.ws_net_profit) - SUM(wr.wr_net_loss)) AS net_profit_after_returns
FROM store s
JOIN date_dim d_store
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_store.d_date_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
WHERE d_store.d_year BETWEEN 2000 AND 2002
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_tax_percentage,
    d_store.d_year,
    d_return.d_year,
    ca_bill.ca_country,
    ca_ship.ca_state,
    ca_returning.ca_city,
    ca_refunded.ca_zip
ORDER BY net_profit_after_returns DESC
LIMIT 100
