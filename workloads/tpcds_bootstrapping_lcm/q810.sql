SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_division_name,
    wp.wp_type,
    d_creation.d_month_seq AS page_creation_month,
    d_access.d_month_seq AS page_access_month,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2020 AND 2022
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_division_name,
    wp.wp_type,
    d_creation.d_month_seq,
    d_access.d_month_seq
ORDER BY total_sales DESC
LIMIT 100
