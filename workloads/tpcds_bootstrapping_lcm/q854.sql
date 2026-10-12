SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    s.s_store_name,
    s.s_city,
    s.s_state,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_ext_tax) AS total_tax,
    SUM(COALESCE(wr.wr_return_tax, 0)) AS total_return_tax,
    (SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_net_loss, 0))) AS net_profit_after_returns,
    CASE
        WHEN SUM(ws.ws_quantity) > 0 THEN SUM(COALESCE(wr.wr_return_quantity, 0)) / CAST(SUM(ws.ws_quantity) AS double)
        ELSE NULL
    END AS return_quantity_ratio
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    s.s_city,
    s.s_state,
    wp.wp_type
ORDER BY net_profit_after_returns DESC
LIMIT 100
