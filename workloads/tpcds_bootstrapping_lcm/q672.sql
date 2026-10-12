WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_sold.d_date AS sold_date,
        d_sold.d_year,
        d_sold.d_month_seq,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT wp.wp_web_page_id) AS page_count,
        SUM(wp.wp_image_count) AS total_images,
        AVG(wp.wp_char_count) AS avg_page_char_count
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN inventory i
        ON i.inv_date_sk = d_sold.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    WHERE d_sold.d_year = 2022
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        d_sold.d_date,
        d_sold.d_year,
        d_sold.d_month_seq
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    sold_date,
    d_year,
    d_month_seq,
    order_count,
    total_sales,
    total_discount,
    total_net_profit,
    total_inventory,
    page_count,
    total_images,
    avg_page_char_count,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
