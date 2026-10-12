SELECT
    s.s_store_name,
    s.s_city,
    s.s_state,
    wp.wp_type,
    d_ret.d_year AS return_year,
    d_ret.d_moy AS return_month,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(date_diff('day', ds.d_date, dsh.d_date)) AS avg_days_to_ship,
    AVG(date_diff('day', dcre.d_date, dacc.d_date)) AS avg_page_lifespan_days,
    CASE
        WHEN SUM(ws.ws_ext_sales_price) > 0
        THEN SUM(cr.cr_return_amount) / SUM(ws.ws_ext_sales_price)
        ELSE NULL
    END AS return_rate,
    ROUND(SUM(ws.ws_net_profit) / NULLIF(COUNT(DISTINCT ws.ws_order_number), 0), 2) AS profit_per_order
FROM catalog_returns cr
JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d_ret.d_date_sk
JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
JOIN date_dim dsh ON ws.ws_ship_date_sk = dsh.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim dcre ON wp.wp_creation_date_sk = dcre.d_date_sk
JOIN date_dim dacc ON wp.wp_access_date_sk = dacc.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    wp.wp_type,
    d_ret.d_year,
    d_ret.d_moy
HAVING SUM(ws.ws_ext_sales_price) > 1000
ORDER BY total_sales DESC
LIMIT 100
