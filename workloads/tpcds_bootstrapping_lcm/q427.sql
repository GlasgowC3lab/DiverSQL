SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_quarter_name AS sold_quarter,
    d_ship.d_month_seq AS ship_month_seq,
    s.s_state,
    s.s_market_desc,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amt,
    COUNT(*) FILTER (WHERE wp.wp_autogen_flag = 'Y') AS auto_generated_pages,
    MAX(d_sold.d_date) AS max_sold_date,
    MIN(d_ship.d_date) AS min_ship_date,
    MIN(d_access.d_date) AS min_access_date
FROM web_sales ws
JOIN date_dim AS d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim AS d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim AS d_creation
    ON wp.wp_creation_date_sk = d_creation.d_date_sk
JOIN date_dim AS d_access
    ON wp.wp_access_date_sk = d_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_creation.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
  AND wp.wp_type IN ('homepage', 'product')
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    d_ship.d_month_seq,
    s.s_state,
    s.s_market_desc,
    wp.wp_type
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY sold_year, sold_quarter, ship_month_seq
LIMIT 100
