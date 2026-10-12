SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    wsite.web_state,
    s.s_state,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_sold,
    SUM(CASE WHEN ws.ws_coupon_amt > 0 THEN 1 ELSE 0 END) AS orders_with_coupon,
    MIN(d_ship.d_date) AS earliest_ship_date,
    MAX(d_ship.d_date) AS latest_ship_date
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_open
    ON wsite.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close
    ON wsite.web_close_date_sk = d_close.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
  AND wsite.web_state = 'CA'
  AND s.s_state = 'CA'
GROUP BY
    d_sold.d_year,
    d_sold.d_month_seq,
    wsite.web_state,
    s.s_state
HAVING SUM(ws.ws_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
