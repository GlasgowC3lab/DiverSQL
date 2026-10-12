SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    d_sold.d_fy_year,
    d_sold.d_fy_quarter_seq,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amt,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_net_loss,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    AVG(wp.wp_image_count) AS avg_image_count,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity
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
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY s.s_store_id, s.s_city, s.s_state, d_sold.d_fy_year, d_sold.d_fy_quarter_seq
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
