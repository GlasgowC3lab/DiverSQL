SELECT
    c.c_birth_country,
    s.s_state,
    ds_sold.d_year,
    ds_sold.d_month_seq,
    CASE WHEN ws.ws_quantity > 10 THEN 'HighQty' ELSE 'LowQty' END AS qty_category,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(wr.wr_return_amt) AS total_return_amount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    MIN(ds_c_first_sales.d_date) AS first_sales_date,
    MAX(ds_c_last_review.d_date) AS last_review_date,
    MIN(ds_c_first_ship.d_date) AS first_ship_date,
    AVG(s.s_floor_space) AS avg_store_floor_space,
    COUNT(DISTINCT c_refund.c_customer_id) AS distinct_refunded_customers,
    COUNT(DISTINCT c_returning.c_customer_id) AS distinct_returning_customers
FROM web_sales ws
JOIN web_returns wr
    ON ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_order_number = wr.wr_order_number
JOIN date_dim ds_sold
    ON ws.ws_sold_date_sk = ds_sold.d_date_sk
JOIN date_dim ds_ship
    ON ws.ws_ship_date_sk = ds_ship.d_date_sk
JOIN date_dim ds_return
    ON wr.wr_returned_date_sk = ds_return.d_date_sk
JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer c_ship
    ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
JOIN customer c_refund
    ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
JOIN customer c_returning
    ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
JOIN store s
    ON true
JOIN date_dim ds_store_closed
    ON s.s_closed_date_sk = ds_store_closed.d_date_sk
JOIN date_dim ds_c_first_ship
    ON c.c_first_shipto_date_sk = ds_c_first_ship.d_date_sk
JOIN date_dim ds_c_first_sales
    ON c.c_first_sales_date_sk = ds_c_first_sales.d_date_sk
JOIN date_dim ds_c_last_review
    ON c.c_last_review_date = ds_c_last_review.d_date_sk
WHERE ds_sold.d_year = 2022
GROUP BY
    c.c_birth_country,
    s.s_state,
    ds_sold.d_year,
    ds_sold.d_month_seq,
    CASE WHEN ws.ws_quantity > 10 THEN 'HighQty' ELSE 'LowQty' END
ORDER BY total_net_profit DESC
LIMIT 100
