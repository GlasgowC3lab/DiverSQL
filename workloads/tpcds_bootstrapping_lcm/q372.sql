SELECT
    c_bill.cd_credit_rating AS bill_credit_rating,
    c_ship.cd_education_status AS ship_education_status,
    d_sold.d_year AS sold_year,
    d_ship.d_month_seq AS ship_month_seq,
    COALESCE(d_return.d_year, 0) AS return_year,
    s.s_market_manager,
    s.s_state,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_ext_sales_price,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amt,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_net_loss
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics c_bill
    ON ws.ws_bill_cdemo_sk = c_bill.cd_demo_sk
JOIN customer_demographics c_ship
    ON ws.ws_ship_cdemo_sk = c_ship.cd_demo_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
LEFT JOIN customer_demographics c_refunded
    ON wr.wr_refunded_cdemo_sk = c_refunded.cd_demo_sk
LEFT JOIN customer_demographics c_returning
    ON wr.wr_returning_cdemo_sk = c_returning.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    c_bill.cd_credit_rating,
    c_ship.cd_education_status,
    d_sold.d_year,
    d_ship.d_month_seq,
    d_return.d_year,
    s.s_market_manager,
    s.s_state
ORDER BY total_net_paid DESC
LIMIT 100
