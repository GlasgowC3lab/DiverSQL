SELECT
  d_sold.d_year AS sales_year,
  d_sold.d_quarter_seq AS sales_quarter,
  d_sold.d_month_seq AS sales_month,
  p.p_promo_name,
  p.p_purpose,
  wsite.web_state AS website_state,
  s.s_state AS store_state,
  CASE
    WHEN p.p_discount_active = 'Y' THEN 'Discounted'
    ELSE 'FullPrice'
  END AS discount_status,
  CASE
    WHEN d_ship.d_weekend = 'Y' THEN 'Weekend'
    ELSE 'Weekday'
  END AS shipping_day_type,
  COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
  SUM(ws.ws_quantity) AS total_quantity,
  SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales_amount,
  SUM(ws.ws_net_profit) AS total_net_profit,
  AVG(ws.ws_sales_price) AS avg_sales_price,
  SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
  MIN(d_sold.d_date) AS first_sale_date,
  MAX(d_sold.d_date) AS last_sale_date
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN store s
  ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_promo_start
  ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
  ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN date_dim d_site_open
  ON wsite.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
  ON wsite.web_close_date_sk = d_site_close.d_date_sk
WHERE d_sold.d_year BETWEEN 2015 AND 2020
  AND wsite.web_state = 'CA'
  AND s.s_state = 'CA'
  AND p.p_discount_active = 'Y'
GROUP BY
  d_sold.d_year,
  d_sold.d_quarter_seq,
  d_sold.d_month_seq,
  p.p_promo_name,
  p.p_purpose,
  wsite.web_state,
  s.s_state,
  CASE
    WHEN p.p_discount_active = 'Y' THEN 'Discounted'
    ELSE 'FullPrice'
  END,
  CASE
    WHEN d_ship.d_weekend = 'Y' THEN 'Weekend'
    ELSE 'Weekday'
  END
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
