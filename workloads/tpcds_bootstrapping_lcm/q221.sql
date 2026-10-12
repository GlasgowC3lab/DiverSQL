SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_month_seq AS ship_month_seq,
    t.t_shift,
    t.t_meal_time,
    site.web_name,
    site.web_state,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    COUNT(*) AS sales_cnt,
    SUM(ws.ws_quantity) AS total_quantity,
    MIN(ws.ws_sales_price) AS min_sales_price,
    MAX(ws.ws_sales_price) AS max_sales_price,
    MIN(d_site_open.d_date) AS site_open_date,
    MAX(d_site_close.d_date) AS site_close_date
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t
  ON ws.ws_sold_time_sk = t.t_time_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN web_site site
  ON ws.ws_web_site_sk = site.web_site_sk
JOIN date_dim d_site_open
  ON site.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
  ON site.web_close_date_sk = d_site_close.d_date_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = 'CA'
  AND site.web_state = 'CA'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    d_ship.d_month_seq,
    t.t_shift,
    t.t_meal_time,
    site.web_name,
    site.web_state
ORDER BY total_net_profit DESC
LIMIT 100
