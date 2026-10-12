SELECT
    d_sold.d_date AS sold_date,
    promotion.p_promo_id,
    promotion.p_discount_active,
    web_site.web_name,
    web_site.web_state,
    MIN(d_site_open.d_date) AS site_open_date,
    MIN(d_site_close.d_date) AS site_close_date,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_quantity) AS total_qty,
    SUM(CAST(ws.ws_quantity * ws.ws_sales_price AS decimal(15,2))) AS total_gross_sales,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MIN(d_ship.d_date) AS first_ship_date,
    MAX(d_ship.d_date) AS last_ship_date,
    MIN(d_store_closed.d_date) AS earliest_store_closed_date,
    MAX(d_store_closed.d_date) AS latest_store_closed_date,
    MIN(d_promo_start.d_date) AS promo_start_date,
    MAX(d_promo_end.d_date) AS promo_end_date
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_site
  ON ws.ws_web_site_sk = web_site.web_site_sk
JOIN date_dim d_site_open
  ON web_site.web_open_date_sk = d_site_open.d_date_sk
JOIN date_dim d_site_close
  ON web_site.web_close_date_sk = d_site_close.d_date_sk
JOIN promotion
  ON ws.ws_promo_sk = promotion.p_promo_sk
JOIN date_dim d_promo_start
  ON promotion.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
  ON promotion.p_end_date_sk = d_promo_end.d_date_sk
JOIN store
  ON store.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_store_closed
  ON store.s_closed_date_sk = d_store_closed.d_date_sk
WHERE d_sold.d_year = 2022
  AND promotion.p_discount_active = 'Y'
  AND web_site.web_state = 'CA'
GROUP BY
    d_sold.d_date,
    promotion.p_promo_id,
    promotion.p_discount_active,
    web_site.web_name,
    web_site.web_state
ORDER BY total_gross_sales DESC
LIMIT 100
