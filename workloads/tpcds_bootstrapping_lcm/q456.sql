SELECT
    s.s_state AS store_state,
    s.s_city AS store_city,
    w.w_warehouse_name AS warehouse_name,
    w.w_city AS warehouse_city,
    wp.wp_type AS page_type,
    d_sold.d_year AS sales_year,
    d_sold.d_month_seq AS sales_month,
    d_creation.d_year AS page_creation_year,
    d_access.d_year AS page_access_year,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(ws.ws_ext_sales_price) / NULLIF(SUM(ws.ws_quantity), 0) AS avg_price_per_item,
    RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
FROM
    web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE
    d_sold.d_year BETWEEN 2020 AND 2022
    AND s.s_state IS NOT NULL
GROUP BY
    s.s_state,
    s.s_city,
    w.w_warehouse_name,
    w.w_city,
    wp.wp_type,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_creation.d_year,
    d_access.d_year
ORDER BY
    profit_rank
LIMIT 100
