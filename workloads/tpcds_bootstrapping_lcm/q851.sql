SELECT
    cd_bill.cd_gender AS bill_gender,
    cd_bill.cd_marital_status AS bill_marital_status,
    cd_ship.cd_credit_rating AS ship_credit_rating,
    d_sold.d_year AS sold_year,
    d_ship.d_year AS ship_year,
    d_creation.d_month_seq AS page_creation_month_seq,
    d_access.d_day_name AS page_access_day_name,
    s.s_state AS store_state,
    s.s_market_manager AS store_market_manager,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(ws.ws_coupon_amt) AS total_coupons,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_web_pages
FROM web_sales ws
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
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
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE cd_bill.cd_gender = 'F'
  AND s.s_state IS NOT NULL
GROUP BY
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    cd_ship.cd_credit_rating,
    d_sold.d_year,
    d_ship.d_year,
    d_creation.d_month_seq,
    d_access.d_day_name,
    s.s_state,
    s.s_market_manager
ORDER BY total_sales DESC
LIMIT 100
