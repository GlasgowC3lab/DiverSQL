SELECT
    sold_year,
    sold_month,
    ship_year,
    item_category,
    item_brand,
    total_quantity,
    total_sales,
    avg_sales_price,
    total_profit,
    distinct_orders,
    store_state,
    store_city,
    page_type,
    page_creation_year,
    page_access_year,
    ROW_NUMBER() OVER (PARTITION BY item_category ORDER BY total_sales DESC) AS category_sales_rank
FROM (
    SELECT
        d_sold.d_year AS sold_year,
        d_sold.d_month_seq AS sold_month,
        d_ship.d_year AS ship_year,
        i.i_category AS item_category,
        i.i_brand AS item_brand,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        s.s_state AS store_state,
        s.s_city AS store_city,
        wp.wp_type AS page_type,
        d_creation.d_year AS page_creation_year,
        d_access.d_year AS page_access_year
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    GROUP BY
        d_sold.d_year,
        d_sold.d_month_seq,
        d_ship.d_year,
        i.i_category,
        i.i_brand,
        s.s_state,
        s.s_city,
        wp.wp_type,
        d_creation.d_year,
        d_access.d_year
) t
ORDER BY total_sales DESC
LIMIT 100
