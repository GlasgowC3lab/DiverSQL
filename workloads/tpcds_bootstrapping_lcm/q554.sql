SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month,
    d_ship.d_year AS ship_year,
    d_ship.d_month_seq AS ship_month,
    cd_bill.cd_gender AS bill_gender,
    cd_bill.cd_credit_rating AS bill_credit_rating,
    cd_ship.cd_gender AS ship_gender,
    cd_ship.cd_credit_rating AS ship_credit_rating,
    wp.wp_type AS page_type,
    d_wp_creation.d_year AS page_creation_year,
    d_wp_access.d_year AS page_access_year,
    s.s_store_name AS store_name,
    s.s_state AS store_state,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_quantity) AS avg_quantity,
    MIN(ws.ws_sales_price) AS min_sales_price,
    MAX(ws.ws_sales_price) AS max_sales_price
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2023
  AND cd_bill.cd_credit_rating = 'A'
  AND s.s_state = 'TX'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_year,
    d_ship.d_month_seq,
    cd_bill.cd_gender,
    cd_bill.cd_credit_rating,
    cd_ship.cd_gender,
    cd_ship.cd_credit_rating,
    wp.wp_type,
    d_wp_creation.d_year,
    d_wp_access.d_year,
    s.s_store_name,
    s.s_state
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 50
