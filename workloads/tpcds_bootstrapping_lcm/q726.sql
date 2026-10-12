SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ds_sold.d_year AS sale_year,
    ds_sold.d_moy AS sale_month,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COALESCE(SUM(wr.wr_return_amt), 0) AS total_return_amount,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    COALESCE(SUM(wr.wr_return_quantity), 0) AS total_quantity_returned,
    COUNT(DISTINCT ca_bill.ca_address_id) AS distinct_bill_addresses,
    COUNT(DISTINCT ca_ship.ca_address_id) AS distinct_ship_addresses,
    COUNT(DISTINCT ca_refund.ca_address_id) AS distinct_refund_addresses,
    COUNT(DISTINCT ca_returning.ca_address_id) AS distinct_returning_addresses
FROM web_sales ws
JOIN date_dim ds_sold
    ON ws.ws_sold_date_sk = ds_sold.d_date_sk
JOIN date_dim ds_ship
    ON ws.ws_ship_date_sk = ds_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = ds_sold.d_date_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
LEFT JOIN date_dim dr_return
    ON wr.wr_returned_date_sk = dr_return.d_date_sk
LEFT JOIN customer_address ca_refund
    ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
LEFT JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    ds_sold.d_year,
    ds_sold.d_moy
