SELECT
    d_ss.d_year AS sales_year,
    d_store_closed.d_year AS store_close_year,
    cc.cc_market_manager,
    s.s_division_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS web_transactions,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(ss.ss_ext_sales_price) AS store_ext_sales,
    SUM(ws.ws_ext_sales_price) AS web_ext_sales,
    AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
    AVG(ws.ws_ext_discount_amt) AS avg_web_discount,
    CASE
        WHEN SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
    END AS profit_flag
FROM store s
JOIN store_sales ss
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_ss
    ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_ss.d_date_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ws_ship.d_date_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_ss.d_year = d_store_closed.d_year
GROUP BY
    d_ss.d_year,
    d_store_closed.d_year,
    cc.cc_market_manager,
    s.s_division_name
HAVING (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) <> 0
ORDER BY store_net_profit DESC
LIMIT 100
