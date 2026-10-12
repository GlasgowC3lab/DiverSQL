SELECT
    d_sold.d_year AS sale_year,
    d_sold.d_month_seq AS month_seq,
    ca_bill.ca_state AS billing_state,
    ca_ship.ca_state AS shipping_state,
    wsit.web_market_manager,
    s.s_market_manager,
    d_site_open.d_year AS site_open_year,
    d_site_close.d_year AS site_close_year,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(
        CASE
            WHEN ws.ws_ext_list_price > 0 THEN
                (ws.ws_ext_list_price - ws.ws_ext_sales_price) / ws.ws_ext_list_price
            ELSE 0
        END
    ) AS avg_discount_ratio,
    SUM(ws.ws_quantity) AS total_quantity
FROM web_sales ws
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_site_open
    ON wsit.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
    ON wsit.web_close_date_sk = d_site_close.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year BETWEEN 2000 AND 2022
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    ca_bill.ca_state,
    ca_ship.ca_state,
    wsit.web_market_manager,
    s.s_market_manager,
    d_site_open.d_year,
    d_site_close.d_year
ORDER BY total_sales DESC
LIMIT 100
