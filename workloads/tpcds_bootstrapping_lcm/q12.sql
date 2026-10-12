WITH base AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        cp.cp_type,
        cp.cp_description,
        d_start.d_year AS start_year,
        d_start.d_month_seq AS start_month,
        d_end.d_year AS end_year,
        d_end.d_month_seq AS end_month,
        s.s_store_id,
        s.s_store_name,
        s.s_state AS store_state,
        s.s_city AS store_city,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws_site.web_site_id,
        ws_site.web_name,
        ws_site.web_state,
        d_site_open.d_year AS site_open_year,
        d_site_open.d_month_seq AS site_open_month,
        d_site_close.d_year AS site_close_year,
        d_site_close.d_month_seq AS site_close_month,
        d_ship.d_year AS ship_year,
        d_ship.d_month_seq AS ship_month
    FROM catalog_page cp
    JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_end.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_start.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN date_dim d_site_open
        ON ws_site.web_open_date_sk = d_site_open.d_date_sk
    JOIN date_dim d_site_close
        ON ws_site.web_close_date_sk = d_site_close.d_date_sk
)
SELECT
    cp_catalog_page_id,
    cp_catalog_number,
    cp_catalog_page_number,
    cp_type,
    start_year,
    start_month,
    end_year,
    end_month,
    ship_year,
    ship_month,
    s_store_id,
    s_store_name,
    store_state,
    store_city,
    web_site_id,
    web_name,
    web_state,
    site_open_year,
    site_open_month,
    site_close_year,
    site_close_month,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    AVG(ws_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    SUM(ws_quantity) AS total_quantity
FROM base
GROUP BY
    cp_catalog_page_id,
    cp_catalog_number,
    cp_catalog_page_number,
    cp_type,
    start_year,
    start_month,
    end_year,
    end_month,
    ship_year,
    ship_month,
    s_store_id,
    s_store_name,
    store_state,
    store_city,
    web_site_id,
    web_name,
    web_state,
    site_open_year,
    site_open_month,
    site_close_year,
    site_close_month
ORDER BY total_profit DESC
LIMIT 100
