SELECT
    s.s_city AS store_city,
    d_sold.d_year AS sale_year,
    d_sold.d_quarter_seq AS sale_quarter,
    i.i_category AS item_category,
    wp.wp_type AS page_type,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount_amount,
    AVG(ws.ws_ext_discount_amt / NULLIF(ws.ws_ext_sales_price, 0)) AS avg_discount_rate,
    AVG(ws.ws_net_profit / NULLIF(ws.ws_ext_sales_price, 0)) AS avg_profit_margin,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items_sold,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages,
    AVG(date_diff('day', d_creation.d_date, d_access.d_date)) AS avg_page_age_days,
    CASE
        WHEN SUM(ws.ws_net_profit) > 100000 THEN 'High'
        WHEN SUM(ws.ws_net_profit) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE
    d_sold.d_year BETWEEN 2020 AND 2022
    AND i.i_wholesale_cost > 50
    AND wp.wp_image_count > 10
    AND s.s_state = 'CA'
    AND d_ship.d_year = d_sold.d_year
GROUP BY
    s.s_city,
    d_sold.d_year,
    d_sold.d_quarter_seq,
    i.i_category,
    wp.wp_type
HAVING
    SUM(ws.ws_ext_sales_price) > 10000
ORDER BY
    total_profit DESC
LIMIT 100
