SELECT
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq AS month_seq,
    CASE
        WHEN c.c_birth_year < 1980 THEN 'Pre-1980'
        WHEN c.c_birth_year BETWEEN 1980 AND 1995 THEN 'Millennial'
        ELSE 'Gen-Z+'
    END AS customer_generation,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
    CASE
        WHEN SUM(ws.ws_quantity) > 0 THEN
            SUM(COALESCE(wr.wr_return_quantity, 0)) * 1.0 / SUM(ws.ws_quantity)
        ELSE 0
    END AS return_rate,
    (SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0))) AS net_profit_after_returns
FROM
    web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
WHERE
    d_sold.d_year BETWEEN 2000 AND 2005
    AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    CASE
        WHEN c.c_birth_year < 1980 THEN 'Pre-1980'
        WHEN c.c_birth_year BETWEEN 1980 AND 1995 THEN 'Millennial'
        ELSE 'Gen-Z+'
    END
HAVING
    SUM(ws.ws_net_profit) > 0
ORDER BY
    d_sold.d_year,
    d_sold.d_month_seq,
    total_sales DESC
LIMIT 100
