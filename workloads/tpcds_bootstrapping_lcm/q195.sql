SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    wsite.web_name,
    wsite.web_state,
    cp.cp_type,
    cp.cp_description,
    d_store.d_date AS store_closed_date,
    d_ship.d_date AS ship_date,
    d_site_open.d_date AS site_open_date,
    d_site_close.d_date AS site_close_date,
    d_catalog_end.d_date AS catalog_end_date,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_sales_price) AS total_sales_price,
    SUM(ws.ws_ext_sales_price) AS total_ext_sales_price,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_ext_tax) AS total_tax,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amount
FROM date_dim d_store
JOIN store s
    ON s.s_closed_date_sk = d_store.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_store.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_site_open
    ON wsite.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
    ON wsite.web_close_date_sk = d_site_close.d_date_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d_store.d_date_sk
JOIN date_dim d_catalog_end
    ON cp.cp_end_date_sk = d_catalog_end.d_date_sk
WHERE d_store.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    wsite.web_name,
    wsite.web_state,
    cp.cp_type,
    cp.cp_description,
    d_store.d_date,
    d_ship.d_date,
    d_site_open.d_date,
    d_site_close.d_date,
    d_catalog_end.d_date
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
