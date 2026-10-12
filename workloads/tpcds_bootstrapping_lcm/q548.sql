WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d_sold.d_date AS sold_date,
        d_ship.d_date AS ship_date,
        t.t_hour,
        t.t_am_pm,
        wp.wp_url,
        wp.wp_type,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        d_creation.d_date AS page_creation_date,
        d_access.d_date AS page_last_access_date
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d_sold.d_date,
        d_ship.d_date,
        t.t_hour,
        t.t_am_pm,
        wp.wp_url,
        wp.wp_type,
        d_creation.d_date,
        d_access.d_date
)
SELECT
    s_store_id,
    s_store_name,
    sold_date,
    ship_date,
    t_hour,
    t_am_pm,
    wp_url,
    wp_type,
    order_count,
    total_quantity,
    total_sales,
    total_ship_cost,
    total_profit,
    total_discount,
    page_creation_date,
    page_last_access_date,
    ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
