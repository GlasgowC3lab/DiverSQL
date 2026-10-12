SELECT
    s.s_store_id,
    s.s_city,
    ws.ws_web_site_sk,
    ws.ws_sold_date_sk,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    MAX(date_diff('day', d_sold.d_date, d_ship.d_date)) AS shipping_delay_days,
    web.web_name,
    web.web_city,
    web.web_state,
    d_site_open.d_date AS site_open_date,
    d_site_close.d_date AS site_close_date,
    MAX(date_diff('day', d_site_open.d_date, d_site_close.d_date)) AS site_lifetime_days,
    cd_bill.cd_gender AS bill_gender,
    cd_bill.cd_marital_status AS bill_marital_status,
    cd_ship.cd_gender AS ship_gender,
    cd_ship.cd_marital_status AS ship_marital_status,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(ws.ws_coupon_amt) AS total_coupons,
    CASE
        WHEN SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_ext_sales_price), 0) > 0.1 THEN 'high'
        ELSE 'low'
    END AS profit_margin_category,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_ext_tax) AS total_tax,
    SUM(ws.ws_ext_ship_cost) AS total_ship_cost
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN web_site web
    ON ws.ws_web_site_sk = web.web_site_sk
JOIN date_dim d_site_open
    ON web.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
    ON web.web_close_date_sk = d_site_close.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_year = 2020
  AND web.web_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_city,
    ws.ws_web_site_sk,
    ws.ws_sold_date_sk,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_sold.d_date,
    d_ship.d_date,
    web.web_name,
    web.web_city,
    web.web_state,
    d_site_open.d_date,
    d_site_close.d_date,
    cd_bill.cd_gender,
    cd_bill.cd_marital_status,
    cd_ship.cd_gender,
    cd_ship.cd_marital_status
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
