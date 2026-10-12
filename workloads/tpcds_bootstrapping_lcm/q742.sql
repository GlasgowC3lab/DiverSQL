WITH sales_agg AS (
  SELECT
    ws.ws_promo_sk,
    ws.ws_web_page_sk,
    ws.ws_sold_date_sk,
    ws.ws_ship_date_sk,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    AVG(ws.ws_sales_price) AS avg_price
  FROM web_sales ws
  GROUP BY
    ws.ws_promo_sk,
    ws.ws_web_page_sk,
    ws.ws_sold_date_sk,
    ws.ws_ship_date_sk
)
SELECT
  d_sold.d_year,
  d_sold.d_month_seq,
  d_ship.d_week_seq,
  p.p_promo_name,
  p.p_discount_active,
  s.s_store_name,
  s.s_state,
  wp.wp_url,
  wp.wp_type,
  sa.total_sales,
  sa.total_discount,
  sa.order_cnt,
  ROUND(sa.avg_price, 2) AS avg_price,
  d_sold.d_date AS store_closed_date,
  d_wp_creation.d_date AS page_creation_date,
  d_wp_access.d_date AS page_access_date,
  d_promo_start.d_date AS promo_start_date,
  d_promo_end.d_date AS promo_end_date
FROM sales_agg sa
JOIN date_dim d_sold
  ON d_sold.d_date_sk = sa.ws_sold_date_sk
JOIN date_dim d_ship
  ON d_ship.d_date_sk = sa.ws_ship_date_sk
JOIN promotion p
  ON p.p_promo_sk = sa.ws_promo_sk
JOIN web_page wp
  ON wp.wp_web_page_sk = sa.ws_web_page_sk
JOIN store s
  ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN date_dim d_promo_start
  ON d_promo_start.d_date_sk = p.p_start_date_sk
JOIN date_dim d_promo_end
  ON d_promo_end.d_date_sk = p.p_end_date_sk
JOIN date_dim d_wp_creation
  ON d_wp_creation.d_date_sk = wp.wp_creation_date_sk
JOIN date_dim d_wp_access
  ON d_wp_access.d_date_sk = wp.wp_access_date_sk
WHERE sa.total_sales > 0
ORDER BY sa.total_sales DESC
LIMIT 100
