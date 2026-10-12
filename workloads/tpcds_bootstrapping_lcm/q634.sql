WITH sales_detail AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_ext_tax,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        s.s_store_name,
        s.s_state,
        s.s_city,
        wp.wp_url,
        wp.wp_image_count,
        wp.wp_char_count,
        ws_site.web_name,
        ws_site.web_state AS site_state,
        ws_site.web_city,
        ws_site.web_zip,
        d_sold.d_year,
        d_sold.d_month_seq,
        d_sold.d_date,
        d_ship.d_date AS ship_date,
        d_store_closed.d_date AS store_closed_date,
        d_site_open.d_date AS site_open_date,
        d_site_close.d_date AS site_close_date,
        d_page_creation.d_date AS page_creation_date,
        d_page_access.d_date AS page_access_date
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ship.d_date_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN date_dim d_site_open
        ON ws_site.web_open_date_sk = d_site_open.d_date_sk
    JOIN date_dim d_site_close
        ON ws_site.web_close_date_sk = d_site_close.d_date_sk
    JOIN date_dim d_page_creation
        ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
    JOIN date_dim d_page_access
        ON wp.wp_access_date_sk = d_page_access.d_date_sk
    WHERE d_sold.d_year BETWEEN 2020 AND 2022
)
SELECT
    d_year,
    d_month_seq,
    s_store_name,
    web_name,
    COUNT(DISTINCT ws_order_number) AS orders,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_sales_price * ws_quantity) AS total_sales_amount,
    SUM(ws_net_profit) AS total_net_profit,
    SUM(ws_ext_discount_amt) AS total_discount,
    AVG(ws_sales_price) AS avg_unit_price,
    MAX(ws_ext_sales_price) AS max_ext_sales_price,
    MIN(ship_date) AS earliest_ship_date,
    MAX(ship_date) AS latest_ship_date
FROM sales_detail
GROUP BY
    d_year,
    d_month_seq,
    s_store_name,
    web_name
HAVING SUM(ws_net_profit) > 0
ORDER BY d_year DESC, d_month_seq, total_net_profit DESC
LIMIT 100
