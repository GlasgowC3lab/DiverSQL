SELECT
    cc.cc_company_name,
    cc_open_dd.d_year AS cc_open_year,
    cc_closed_dd.d_year AS cc_closed_year,
    s.s_store_name,
    sale_dd.d_current_month,
    i.i_category,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_ship_cost) AS avg_ship_cost,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt
FROM web_sales ws
JOIN date_dim sale_dd
    ON ws.ws_sold_date_sk = sale_dd.d_date_sk
JOIN date_dim ship_dd
    ON ws.ws_ship_date_sk = ship_dd.d_date_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = ship_dd.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = ship_dd.d_date_sk
JOIN date_dim cc_open_dd
    ON cc.cc_open_date_sk = cc_open_dd.d_date_sk
JOIN date_dim cc_closed_dd
    ON cc.cc_closed_date_sk = cc_closed_dd.d_date_sk
WHERE i.i_category = 'Sports'
  AND sale_dd.d_current_quarter = ship_dd.d_current_quarter
GROUP BY
    cc.cc_company_name,
    cc_open_dd.d_year,
    cc_closed_dd.d_year,
    s.s_store_name,
    sale_dd.d_current_month,
    i.i_category
HAVING SUM(ws.ws_ext_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 100
