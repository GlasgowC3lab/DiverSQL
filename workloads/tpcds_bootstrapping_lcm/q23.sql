SELECT
    cc.cc_division,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city AS store_city,
    d.d_year AS common_year,
    d.d_month_seq AS common_month_seq,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_returns,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(cr.cr_return_quantity) AS avg_return_quantity
FROM date_dim d
JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
    AND cc.cc_open_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_ship_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
GROUP BY
    cc.cc_division,
    cc.cc_city,
    cc.cc_state,
    s.s_store_name,
    s.s_city,
    d.d_year,
    d.d_month_seq
ORDER BY total_net_profit DESC
LIMIT 100
