SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    cp.cp_type,
    cp.cp_department,
    d_sold.d_year AS sold_year,
    d_sold.d_month_seq AS sold_month_seq,
    d_ship.d_year AS ship_year,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) AS profit_margin,
    AVG(date_diff('day', d_sold.d_date, d_ship.d_date)) AS avg_days_to_ship,
    CASE
        WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_indicator,
    (cc.cc_tax_percentage + s.s_tax_percentage) AS total_tax_percent,
    SUM(ws.ws_ext_sales_price) * (1 + (cc.cc_tax_percentage + s.s_tax_percentage) / 100) AS sales_including_tax
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ship.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
  AND d_ship.d_year = 2022
  AND cc.cc_tax_percentage > 0
  AND s.s_tax_percentage > 0
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    cp.cp_type,
    cp.cp_department,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_year,
    cc.cc_tax_percentage,
    s.s_tax_percentage
ORDER BY total_sales DESC
LIMIT 100
