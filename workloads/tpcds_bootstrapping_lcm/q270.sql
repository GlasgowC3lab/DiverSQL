SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS sale_month_seq,
    s.s_store_name,
    wsite.web_name,
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    CASE
        WHEN ws.ws_net_paid >= 1000 THEN 'High'
        WHEN ws.ws_net_paid >= 500 THEN 'Medium'
        ELSE 'Low'
    END AS payment_tier,
    COUNT(*) AS total_transactions,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN ws.ws_ship_date_sk = ws.ws_sold_date_sk THEN 1 ELSE 0 END) AS same_day_ship_cnt,
    SUM(CASE WHEN d_ship.d_weekend = 'Y' THEN ws.ws_ext_sales_price ELSE 0 END) AS weekend_sales,
    SUM(CASE WHEN d_ship.d_holiday = 'Y' THEN ws.ws_ext_sales_price ELSE 0 END) AS holiday_sales,
    MIN(cd_ship.cd_credit_rating) AS ship_credit_rating_min,
    MAX(cd_ship.cd_credit_rating) AS ship_credit_rating_max
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_site_open
    ON wsite.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
    ON wsite.web_close_date_sk = d_site_close.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    s.s_store_name,
    wsite.web_name,
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    CASE
        WHEN ws.ws_net_paid >= 1000 THEN 'High'
        WHEN ws.ws_net_paid >= 500 THEN 'Medium'
        ELSE 'Low'
    END
ORDER BY total_sales DESC
LIMIT 100
