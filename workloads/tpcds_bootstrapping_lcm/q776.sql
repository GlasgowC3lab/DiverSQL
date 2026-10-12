SELECT
    s.s_store_name,
    s.s_city AS store_city,
    s.s_state AS store_state,
    ws_site.web_name,
    ws_site.web_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_coupon_amt) AS avg_coupon,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT ca_bill.ca_address_sk) AS distinct_bill_addresses,
    COUNT(DISTINCT ca_ship.ca_address_sk) AS distinct_ship_addresses,
    MIN(d_ship.d_week_seq) AS first_ship_week,
    MAX(d_ship.d_week_seq) AS last_ship_week,
    d_site_open.d_year AS site_open_year,
    d_site_close.d_year AS site_close_year
FROM web_sales ws
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site ws_site
    ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN date_dim d_site_open
    ON ws_site.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
    ON ws_site.web_close_date_sk = d_site_close.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2019 AND 2021
  AND s.s_state = ca_ship.ca_state
GROUP BY
    s.s_store_name,
    s.s_city,
    s.s_state,
    ws_site.web_name,
    ws_site.web_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_site_open.d_year,
    d_site_close.d_year
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 100
