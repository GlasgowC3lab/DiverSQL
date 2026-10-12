SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month_seq,
    d_ship.d_year AS ship_year,
    s.s_store_name,
    s.s_state,
    cc.cc_market_manager,
    cc.cc_tax_percentage,
    cp.cp_type,
    cp.cp_description,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
CROSS JOIN call_center cc
JOIN date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
CROSS JOIN catalog_page cp
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE
    d_sold.d_year BETWEEN 2001 AND 2003
    AND s.s_state = 'CA'
    AND cc.cc_tax_percentage > 5.00
    AND cp.cp_type = 'PROMO'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_year,
    s.s_store_name,
    s.s_state,
    cc.cc_market_manager,
    cc.cc_tax_percentage,
    cp.cp_type,
    cp.cp_description
HAVING
    SUM(ws.ws_net_profit) > 5000
ORDER BY total_net_profit DESC
LIMIT 100
