SELECT
    ca_bill.ca_city AS billing_city,
    ca_ship.ca_city AS shipping_city,
    s.s_division_name AS store_division,
    dd_store_closed.d_year AS sold_year,
    dd_store_closed.d_month_seq AS sold_month,
    dd_site_open.d_year AS site_open_year,
    dd_site_open.d_month_seq AS site_open_month,
    wsit.web_name AS website_name,
    CASE WHEN ca_bill.ca_state IN ('CA','WA','OR') THEN 'West' ELSE 'Other' END AS region_group,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_quantity) AS avg_quantity,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM store s
JOIN date_dim dd_store_closed
    ON s.s_closed_date_sk = dd_store_closed.d_date_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = dd_store_closed.d_date_sk
JOIN customer_address ca_bill
    ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN date_dim dd_ship
    ON ws.ws_ship_date_sk = dd_ship.d_date_sk
JOIN web_site wsit
    ON ws.ws_web_site_sk = wsit.web_site_sk
JOIN date_dim dd_site_open
    ON wsit.web_open_date_sk = dd_site_open.d_date_sk
JOIN date_dim dd_site_close
    ON wsit.web_close_date_sk = dd_site_close.d_date_sk
WHERE date_diff('day', dd_store_closed.d_date, dd_ship.d_date) BETWEEN 0 AND 7
  AND dd_site_open.d_date <= dd_store_closed.d_date
  AND (dd_site_close.d_date IS NULL OR dd_site_close.d_date > dd_store_closed.d_date)
GROUP BY
    ca_bill.ca_city,
    ca_ship.ca_city,
    s.s_division_name,
    dd_store_closed.d_year,
    dd_store_closed.d_month_seq,
    dd_site_open.d_year,
    dd_site_open.d_month_seq,
    wsit.web_name,
    CASE WHEN ca_bill.ca_state IN ('CA','WA','OR') THEN 'West' ELSE 'Other' END
HAVING SUM(ws.ws_net_profit) > 0
   AND AVG(ws.ws_quantity) > 5
ORDER BY total_net_profit DESC
LIMIT 100
