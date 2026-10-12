SELECT
    cc.cc_call_center_id,
    cc.cc_manager,
    d_date_open.d_year AS cc_open_year,
    d_date_closed.d_year AS cc_closed_year,
    d_sold.d_year AS sold_year,
    d_ship.d_year AS ship_year,
    i.i_category,
    i.i_product_name,
    s.s_store_name,
    s.s_city,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    CASE
        WHEN SUM(ws.ws_quantity) = 0 THEN 0
        ELSE SUM(ws.ws_net_profit) / SUM(ws.ws_quantity)
    END AS profit_per_unit
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
CROSS JOIN date_dim d_date_closed
JOIN store s ON s.s_closed_date_sk = d_date_closed.d_date_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_date_closed.d_date_sk
JOIN date_dim d_date_open ON cc.cc_open_date_sk = d_date_open.d_date_sk
WHERE d_sold.d_year = 2020
  AND ws.ws_net_profit > 0
GROUP BY
    cc.cc_call_center_id,
    cc.cc_manager,
    d_date_open.d_year,
    d_date_closed.d_year,
    d_sold.d_year,
    d_ship.d_year,
    i.i_category,
    i.i_product_name,
    s.s_store_name,
    s.s_city
ORDER BY total_profit DESC
LIMIT 100
