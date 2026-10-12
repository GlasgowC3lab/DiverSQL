SELECT
    s.s_store_id,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
    MIN(ws.ws_ship_date_sk) AS earliest_ship_date_sk,
    MAX(ws.ws_ship_date_sk) AS latest_ship_date_sk,
    MIN(d_ship.d_dow) AS min_ship_day_of_week,
    w.web_name,
    w.web_state,
    d_open.d_current_year AS web_open_year,
    d_close.d_current_year AS web_close_year
FROM web_sales ws
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
JOIN date_dim d_open ON w.web_open_date_sk = d_open.d_date_sk
JOIN date_dim d_close ON w.web_close_date_sk = d_close.d_date_sk
JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_close.d_date_sk
WHERE d_sold.d_year = 2022
  AND w.web_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_city,
    d_sold.d_year,
    d_sold.d_month_seq,
    w.web_name,
    w.web_state,
    d_open.d_current_year,
    d_close.d_current_year
HAVING COUNT(DISTINCT ws.ws_order_number) > 10
ORDER BY total_sales DESC
LIMIT 100
