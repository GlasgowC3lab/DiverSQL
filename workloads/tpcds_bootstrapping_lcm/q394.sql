SELECT
    cc.cc_country AS country,
    cc.cc_state AS call_center_state,
    s.s_state AS store_state,
    s.s_city AS store_city,
    d_ret.d_year AS year,
    d_ret.d_quarter_name AS quarter,
    d_ship.d_month_seq AS shipping_month,
    CASE WHEN ws.ws_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_net_paid) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(cr.cr_return_quantity) AS total_quantity_returned,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    AVG(date_diff('day', d_cc.d_date, d_ret.d_date)) AS avg_days_between_closed_and_return,
    SUM(ws.ws_sales_price * ws.ws_quantity) - SUM(cr.cr_return_amount) AS net_sales_minus_returns,
    (SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss)) / NULLIF(SUM(ws.ws_net_paid), 0) AS profit_margin_after_returns
FROM call_center cc
JOIN catalog_returns cr
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_ret.d_date_sk
JOIN date_dim d_cc
    ON cc.cc_closed_date_sk = d_cc.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
WHERE d_ret.d_year BETWEEN 2000 AND 2005
GROUP BY
    cc.cc_country,
    cc.cc_state,
    s.s_state,
    s.s_city,
    d_ret.d_year,
    d_ret.d_quarter_name,
    d_ship.d_month_seq,
    CASE WHEN ws.ws_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END
HAVING COUNT(DISTINCT ws.ws_order_number) > 10
ORDER BY total_sales DESC
LIMIT 100
