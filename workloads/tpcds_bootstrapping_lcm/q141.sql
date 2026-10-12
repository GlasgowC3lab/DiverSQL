SELECT
    cd.cd_gender,
    cd.cd_marital_status,
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    s.s_city,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_coupon_amt) AS avg_coupon,
    COUNT(DISTINCT wp.wp_web_page_id) AS distinct_pages,
    MIN(d_page_creation.d_date) AS earliest_page_creation,
    MAX(d_page_access.d_date) AS latest_page_access
FROM customer_demographics cd
JOIN web_sales ws
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE cd.cd_credit_rating = 'Excellent'
  AND s.s_state = 'CA'
  AND d_sold.d_year = 2022
GROUP BY
    cd.cd_gender,
    cd.cd_marital_status,
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    s.s_city
HAVING SUM(ws.ws_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
