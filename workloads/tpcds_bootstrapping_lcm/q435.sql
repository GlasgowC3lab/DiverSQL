SELECT
    cc.cc_call_center_id,
    cc.cc_name AS call_center_name,
    cc.cc_state,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_closed.d_year AS closed_year,
    d_closed.d_month_seq AS closed_month,
    d_open.d_year AS open_year,
    d_open.d_month_seq AS open_month,
    MIN(d_wp_creation.d_date) AS earliest_page_creation,
    MIN(d_wp_access.d_date) AS earliest_page_access,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_ext_sales_price) AS total_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(wp.wp_image_count) AS avg_image_count,
    AVG(wp.wp_link_count) AS avg_link_count,
    COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_web_pages
FROM call_center cc
JOIN date_dim d_closed
  ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_closed.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
  ON cc.cc_open_date_sk = d_open.d_date_sk
   AND ws.ws_ship_date_sk = d_open.d_date_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_wp_creation
  ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
  ON wp.wp_access_date_sk = d_wp_access.d_date_sk
WHERE d_closed.d_year BETWEEN 2000 AND 2005
  AND cc.cc_state = s.s_state
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    cc.cc_state,
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    d_closed.d_year,
    d_closed.d_month_seq,
    d_open.d_year,
    d_open.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
