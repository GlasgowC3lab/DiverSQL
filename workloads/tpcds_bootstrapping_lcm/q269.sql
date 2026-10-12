WITH daily_summary AS (
    SELECT
        d_ret.d_date AS return_date,
        d_ret.d_year AS return_year,
        s.s_store_name AS store_name,
        s.s_city AS store_city,
        s.s_state AS store_state,
        wp.wp_url AS page_url,
        wp.wp_type AS page_type,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT ws.ws_order_number) AS sales_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        d_ship.d_date AS ship_date,
        d_creation.d_date AS page_creation_date,
        d_access.d_date AS page_access_date
    FROM catalog_returns cr
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_ret.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_creation
        ON wp.wp_creation_date_sk = d_creation.d_date_sk
    JOIN date_dim d_access
        ON wp.wp_access_date_sk = d_access.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    WHERE cr.cr_return_quantity > 0
    GROUP BY
        d_ret.d_date,
        d_ret.d_year,
        s.s_store_name,
        s.s_city,
        s.s_state,
        wp.wp_url,
        wp.wp_type,
        d_ship.d_date,
        d_creation.d_date,
        d_access.d_date
)
SELECT
    return_date,
    return_year,
    store_name,
    store_city,
    store_state,
    page_url,
    page_type,
    return_orders,
    total_return_amount,
    total_net_loss,
    sales_orders,
    total_sales_amount,
    total_net_profit,
    ship_date,
    page_creation_date,
    page_access_date,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM daily_summary
ORDER BY profit_rank
LIMIT 100
