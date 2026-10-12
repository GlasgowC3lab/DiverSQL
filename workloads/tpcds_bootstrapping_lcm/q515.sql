SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_date AS common_date,
    ca_bill.ca_city AS bill_city,
    ca_ship.ca_city AS ship_city,
    ca_refunded.ca_city AS refunded_city,
    ca_returning.ca_city AS returning_city,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_ext_ship_cost) AS total_shipping_cost,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT wr.wr_order_number) AS num_returns,
    AVG(cs.cs_quantity) AS avg_quantity,
    AVG(wr.wr_return_quantity) AS avg_return_quantity
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
   AND cs.cs_ship_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN customer_address ca_refunded
    ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d.d_date,
    ca_bill.ca_city,
    ca_ship.ca_city,
    ca_refunded.ca_city,
    ca_returning.ca_city
ORDER BY total_net_profit DESC
LIMIT 100
