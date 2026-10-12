SELECT
    concat(cast(d_ret.d_year AS varchar), '-', lpad(cast(d_ret.d_moy AS varchar), 2, '0')) AS year_month,
    s.s_state AS store_state,
    s.s_city AS store_city,
    wp.wp_type AS page_type,
    count(DISTINCT ws.ws_order_number) AS distinct_sales_orders,
    sum(ws.ws_quantity) AS total_quantity_sold,
    sum(cr.cr_return_quantity) AS total_quantity_returned,
    sum(ws.ws_net_paid_inc_ship_tax) AS total_sales_amount,
    sum(ws.ws_net_profit) AS total_profit,
    sum(cr.cr_net_loss) AS total_return_loss,
    avg(ws.ws_sales_price) AS avg_sales_price,
    sum(CASE WHEN d_ret.d_year = d_wp_creation.d_year THEN ws.ws_net_paid_inc_ship_tax ELSE 0 END) AS sales_same_year_as_page_creation,
    sum(CASE WHEN d_ws_ship.d_year = d_wp_access.d_year THEN ws.ws_ext_tax ELSE 0 END) AS tax_same_year_as_page_access
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_ret.d_date_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE cr.cr_net_loss > 0
  AND ws.ws_net_profit > 0
  AND d_ret.d_year BETWEEN 2015 AND 2022
GROUP BY
    concat(cast(d_ret.d_year AS varchar), '-', lpad(cast(d_ret.d_moy AS varchar), 2, '0')),
    s.s_state,
    s.s_city,
    wp.wp_type
