SELECT
    s.s_store_id,
    s.s_city,
    s.s_state,
    sold_date.d_year AS sold_year,
    sold_date.d_month_seq AS sold_month,
    bill_cdemo.cd_gender AS bill_gender,
    bill_cdemo.cd_marital_status AS bill_marital_status,
    ship_cdemo.cd_gender AS ship_gender,
    ship_cdemo.cd_education_status AS ship_education,
    CASE
        WHEN bill_cdemo.cd_credit_rating = 'A' THEN 'High'
        WHEN bill_cdemo.cd_credit_rating = 'B' THEN 'Medium'
        ELSE 'Low'
    END AS credit_rating_category,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_quantity) AS avg_quantity,
    SUM(ws.ws_coupon_amt) AS total_coupons,
    MIN(s.s_tax_percentage) AS min_tax_pct,
    MAX(s.s_tax_percentage) AS max_tax_pct,
    SUM(ws.ws_ext_sales_price) FILTER (WHERE wp.wp_type = 'Home') AS home_page_sales,
    SUM(ws.ws_ext_sales_price) FILTER (WHERE wp.wp_type = 'Product') AS product_page_sales,
    COUNT(CASE WHEN wp.wp_image_count > 10 THEN 1 END) AS pages_with_many_images
FROM web_sales ws
JOIN date_dim sold_date
    ON ws.ws_sold_date_sk = sold_date.d_date_sk
JOIN date_dim ship_date
    ON ws.ws_ship_date_sk = ship_date.d_date_sk
JOIN customer_demographics bill_cdemo
    ON ws.ws_bill_cdemo_sk = bill_cdemo.cd_demo_sk
JOIN customer_demographics ship_cdemo
    ON ws.ws_ship_cdemo_sk = ship_cdemo.cd_demo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim page_creation_date
    ON wp.wp_creation_date_sk = page_creation_date.d_date_sk
JOIN date_dim page_access_date
    ON wp.wp_access_date_sk = page_access_date.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = ship_date.d_date_sk
WHERE sold_date.d_year = 2022
  AND s.s_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_city,
    s.s_state,
    sold_date.d_year,
    sold_date.d_month_seq,
    bill_cdemo.cd_gender,
    bill_cdemo.cd_marital_status,
    ship_cdemo.cd_gender,
    ship_cdemo.cd_education_status,
    CASE
        WHEN bill_cdemo.cd_credit_rating = 'A' THEN 'High'
        WHEN bill_cdemo.cd_credit_rating = 'B' THEN 'Medium'
        ELSE 'Low'
    END
ORDER BY total_sales DESC
LIMIT 100
