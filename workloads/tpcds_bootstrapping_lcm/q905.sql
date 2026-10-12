SELECT
    cc.cc_name,
    cc.cc_country,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_ship_cost) AS avg_ship_cost,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_ext_sales_price) - SUM(ws.ws_ext_discount_amt) AS net_sales,
    CASE
        WHEN SUM(ws.ws_ext_sales_price) = 0 THEN NULL
        ELSE SUM(ws.ws_net_profit) / SUM(ws.ws_ext_sales_price)
    END AS profit_margin
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN call_center cc
    ON cc.cc_open_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2002
GROUP BY
    cc.cc_name,
    cc.cc_country,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq
HAVING SUM(ws.ws_ext_sales_price) > 100000
ORDER BY total_sales DESC
LIMIT 50
