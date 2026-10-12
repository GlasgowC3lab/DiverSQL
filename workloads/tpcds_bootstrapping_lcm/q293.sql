SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    CASE
        WHEN d_sold.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_sold.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_sold.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS sale_quarter,
    s.s_state AS store_state,
    cc.cc_division_name AS call_center_division,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
    SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(wr.wr_return_amt_inc_tax, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    (SUM(ws.ws_ext_sales_price) - SUM(COALESCE(wr.wr_return_amt_inc_tax, 0))) AS net_sales_after_returns
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
LEFT JOIN web_returns wr
    ON ws.ws_item_sk = wr.wr_item_sk
    AND ws.ws_order_number = wr.wr_order_number
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ship.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_sold.d_year = 2020
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    CASE
        WHEN d_sold.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_sold.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_sold.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END,
    s.s_state,
    cc.cc_division_name
HAVING SUM(ws.ws_ext_sales_price) > 0
ORDER BY net_sales_after_returns DESC
LIMIT 100
