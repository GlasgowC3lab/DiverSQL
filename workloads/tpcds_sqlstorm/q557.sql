WITH sales_union AS (
  SELECT
    'Catalog' AS channel,
    cd.d_year,
    cd.d_month_seq,
    cs.cs_order_number AS order_num,
    CONCAT('CATALOG_ORDER_', CAST(cs.cs_order_number AS varchar)) AS order_id,
    i.i_product_name AS product_name,
    LOWER(i.i_product_name) AS product_name_lcase,
    LENGTH(i.i_product_name) AS product_name_len,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
    REGEXP_REPLACE(c.c_email_address, '([^@]+)@.*', '\\1') AS email_user,
    CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number) AS street_address,
    CONCAT_WS(', ', ca.ca_city, ca.ca_state, ca.ca_zip) AS city_state_zip,
    p.p_promo_name AS promo_name,
    REGEXP_REPLACE(p.p_promo_name, '[^A-Za-z]', '_') AS promo_name_sanitized,
    REGEXP_REPLACE(REGEXP_REPLACE(p.p_promo_name, '[A-Za-z]', '*'), '[^_]', '*') AS promo_name_masked,
    cs.cs_net_paid_inc_tax AS revenue
  FROM catalog_sales cs
  LEFT JOIN date_dim cd ON cs.cs_sold_date_sk = cd.d_date_sk
  LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk

  UNION ALL

  SELECT
    'Store' AS channel,
    sd.d_year,
    sd.d_month_seq,
    ss.ss_ticket_number AS order_num,
    CONCAT('STORE_ORDER_', CAST(ss.ss_ticket_number AS varchar)) AS order_id,
    i.i_product_name AS product_name,
    LOWER(i.i_product_name) AS product_name_lcase,
    LENGTH(i.i_product_name) AS product_name_len,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
    REGEXP_REPLACE(c.c_email_address, '([^@]+)@.*', '\\1') AS email_user,
    CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number) AS street_address,
    CONCAT_WS(', ', ca.ca_city, ca.ca_state, ca.ca_zip) AS city_state_zip,
    p.p_promo_name AS promo_name,
    REGEXP_REPLACE(p.p_promo_name, '[^A-Za-z]', '_') AS promo_name_sanitized,
    REGEXP_REPLACE(REGEXP_REPLACE(p.p_promo_name, '[A-Za-z]', '*'), '[^_]', '*') AS promo_name_masked,
    ss.ss_net_paid_inc_tax AS revenue
  FROM store_sales ss
  LEFT JOIN date_dim sd ON ss.ss_sold_date_sk = sd.d_date_sk
  LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
  LEFT JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk

  UNION ALL

  SELECT
    'Web' AS channel,
    wd.d_year,
    wd.d_month_seq,
    ws.ws_order_number AS order_num,
    CONCAT('WEB_ORDER_', CAST(ws.ws_order_number AS varchar)) AS order_id,
    i.i_product_name AS product_name,
    LOWER(i.i_product_name) AS product_name_lcase,
    LENGTH(i.i_product_name) AS product_name_len,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
    REGEXP_REPLACE(c.c_email_address, '([^@]+)@.*', '\\1') AS email_user,
    CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number) AS street_address,
    CONCAT_WS(', ', ca.ca_city, ca.ca_state, ca.ca_zip) AS city_state_zip,
    p.p_promo_name AS promo_name,
    REGEXP_REPLACE(p.p_promo_name, '[^A-Za-z]', '_') AS promo_name_sanitized,
    REGEXP_REPLACE(REGEXP_REPLACE(p.p_promo_name, '[A-Za-z]', '*'), '[^_]', '*') AS promo_name_masked,
    ws.ws_net_paid_inc_tax AS revenue
  FROM web_sales ws
  LEFT JOIN date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
  LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
  LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
)

SELECT
  channel,
  d_year,
  d_month_seq,
  COUNT(*) AS order_count,
  SUM(revenue) AS total_revenue,
  AVG(product_name_len) AS avg_product_name_len,
  MAX(product_name_len) AS max_product_name_len,
  MIN(product_name_len) AS min_product_name_len,
  COUNT(DISTINCT customer_full_name) AS distinct_customers,
  COUNT(DISTINCT email_user) AS distinct_email_users,
  COUNT(DISTINCT street_address) AS distinct_street_addresses,
  ARRAY_JOIN(ARRAY_AGG(DISTINCT city_state_zip), ', ') AS distinct_city_state_zips
FROM sales_union
GROUP BY
  channel,
  d_year,
  d_month_seq
