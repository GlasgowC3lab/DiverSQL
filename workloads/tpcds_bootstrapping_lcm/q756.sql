WITH sales_summary AS (
    SELECT
        ca_bill.ca_city AS billing_city,
        ca_ship.ca_city AS shipping_city,
        d_sold.d_year AS sale_year,
        d_sold.d_month_seq AS sale_month_seq,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        wp.wp_url AS page_url,
        wp.wp_type AS page_type,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM web_sales ws
    JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_page_creation ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
    JOIN date_dim d_page_access ON wp.wp_access_date_sk = d_page_access.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    GROUP BY
        ca_bill.ca_city,
        ca_ship.ca_city,
        d_sold.d_year,
        d_sold.d_month_seq,
        s.s_store_name,
        s.s_city,
        s.s_state,
        wp.wp_url,
        wp.wp_type
)
SELECT
    billing_city,
    shipping_city,
    sale_year,
    sale_month_seq,
    store_name,
    store_city,
    store_state,
    page_url,
    page_type,
    total_sales,
    total_profit,
    order_count,
    avg_quantity,
    ROW_NUMBER() OVER (PARTITION BY billing_city ORDER BY total_sales DESC) AS sales_rank_by_city
FROM sales_summary
ORDER BY total_sales DESC
LIMIT 100
