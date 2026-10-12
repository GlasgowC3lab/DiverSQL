SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_date AS sale_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_day_name AS ship_day_name,
    ca_bill.ca_city AS billing_city,
    ca_ship.ca_city AS shipping_city,
    ca_refund.ca_city AS refund_city,
    ca_returning.ca_city AS returning_city,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
    MIN(d_return.d_date) AS earliest_return_date,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_returns
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN customer_address ca_refund
    ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
LEFT JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_date,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_day_name,
    ca_bill.ca_city,
    ca_ship.ca_city,
    ca_refund.ca_city,
    ca_returning.ca_city
ORDER BY total_sales_amount DESC
LIMIT 100
