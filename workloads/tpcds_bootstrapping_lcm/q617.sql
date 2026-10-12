SELECT
    c.c_customer_id,
    d_sold.d_year,
    d_sold.d_month_seq AS sale_month_seq,
    d_ship.d_month_seq AS ship_month_seq,
    s.s_state,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    SUM(ws.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit_after_returns,
    AVG(ws.ws_quantity) AS avg_quantity,
    CASE
        WHEN SUM(ws.ws_net_paid) > 200000 THEN 'PLATINUM'
        WHEN SUM(ws.ws_net_paid) > 100000 THEN 'GOLD'
        WHEN SUM(ws.ws_net_paid) > 50000 THEN 'SILVER'
        ELSE 'BRONZE'
    END AS revenue_tier
FROM customer c
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_cust_first_sales
    ON c.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    c.c_customer_id,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_month_seq,
    s.s_state
HAVING COUNT(DISTINCT ws.ws_order_number) > 3
ORDER BY net_profit_after_returns DESC
LIMIT 100
