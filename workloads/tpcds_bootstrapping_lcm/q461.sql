SELECT
    cc.cc_name AS call_center_name,
    cc.cc_market_manager AS market_manager,
    s.s_store_name AS store_name,
    d_sold.d_year AS sales_year,
    d_sold.d_month_seq AS sales_month_seq,
    MIN(d_ship.d_date) AS earliest_catalog_ship_date,
    MAX(d_ws_ship.d_date) AS latest_web_ship_date,
    MIN(d_cc_open.d_date) AS call_center_open_date,
    MAX(d_cc_closed.d_date) AS call_center_closed_date,
    MAX(d_store_closed.d_date) AS store_closed_date,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    SUM(cs.cs_net_profit) AS total_catalog_net_profit,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    (SUM(cs.cs_net_paid) + SUM(ws.ws_net_paid)) AS total_net_paid
FROM
    catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cc_closed
        ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
    JOIN date_dim d_cc_open
        ON cc.cc_open_date_sk = d_cc_open.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE
    d_sold.d_year = 2001
GROUP BY
    cc.cc_name,
    cc.cc_market_manager,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_month_seq
ORDER BY
    total_net_paid DESC
LIMIT 100
