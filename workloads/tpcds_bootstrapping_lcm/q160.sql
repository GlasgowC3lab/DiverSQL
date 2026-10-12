SELECT
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month,
    d_return.d_year AS return_year,
    ca_bill.ca_city AS billing_city,
    ca_ship.ca_state AS shipping_state,
    CASE WHEN ca_bill.ca_state = 'CA' THEN 'California' ELSE 'Other' END AS billing_state_group,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(ws.ws_ext_discount_amt) / NULLIF(SUM(ws.ws_quantity), 0) AS avg_discount_per_item,
    (SUM(ws.ws_net_profit) - SUM(wr.wr_net_loss)) / NULLIF(SUM(ws.ws_ext_sales_price), 0) * 100 AS net_profit_margin_percent,
    SUM(wr.wr_return_quantity) * 100.0 / NULLIF(SUM(ws.ws_quantity), 0) AS return_rate_percent
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN customer_address ca_refund ON wr.wr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
JOIN store s ON s.s_closed_date_sk = d_return.d_date_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_year,
    d_ship.d_month_seq,
    d_return.d_year,
    ca_bill.ca_city,
    ca_ship.ca_state,
    CASE WHEN ca_bill.ca_state = 'CA' THEN 'California' ELSE 'Other' END
ORDER BY total_sales_amount DESC
LIMIT 100
