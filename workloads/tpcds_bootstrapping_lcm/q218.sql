SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_moy AS month,
    COUNT(DISTINCT cust_bill.c_customer_id) AS distinct_customers,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    SUM(ws.ws_ext_sales_price) - SUM(COALESCE(wr.wr_net_loss, 0)) AS net_revenue,
    AVG(ws.ws_ext_ship_cost) AS avg_ship_cost,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_quantity_returned
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN customer cust_bill
    ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN customer cust_return
    ON wr.wr_refunded_customer_sk = cust_return.c_customer_sk
LEFT JOIN customer cust_returning
    ON wr.wr_returning_customer_sk = cust_returning.c_customer_sk
WHERE d_sold.d_year = 2022
  AND cust_bill.c_birth_month = d_sold.d_moy
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_sold.d_year,
    d_sold.d_moy
ORDER BY net_revenue DESC
LIMIT 100
