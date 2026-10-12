SELECT
    d_sold.d_year AS sold_year,
    d_sold.d_quarter_name AS sold_quarter,
    s.s_city AS store_city,
    wsite.web_name AS site_name,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    (SUM(ws.ws_net_profit) - SUM(COALESCE(wr.wr_return_amt, 0))) AS net_profit_after_returns,
    AVG(ws.ws_coupon_amt) AS avg_coupon_amount,
    MIN(d_return.d_date) AS first_return_date,
    MAX(d_return.d_date) AS last_return_date
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN date_dim d_site_open
  ON wsite.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
  ON wsite.web_close_date_sk = d_site_close.d_date_sk
JOIN web_returns wr
  ON wr.wr_item_sk = ws.ws_item_sk
 AND wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_return
  ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_sold.d_year >= 2020
GROUP BY
    d_sold.d_year,
    d_sold.d_quarter_name,
    s.s_city,
    wsite.web_name
ORDER BY net_profit_after_returns DESC
LIMIT 100
