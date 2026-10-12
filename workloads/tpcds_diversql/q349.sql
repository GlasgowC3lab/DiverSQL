WITH
  sales_pre AS (
    SELECT
      ss.ss_ticket_number AS order_number,
      dd.d_year,
      s.s_store_id,
      s.s_state,
      cd.cd_gender,
      cd.cd_purchase_estimate,
      ss.ss_net_paid AS net_amount,
      wp.wp_url,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_net_paid DESC) AS rn,
      LAG(ss.ss_net_paid) OVER (PARTITION BY s.s_store_id ORDER BY dd.d_date) AS lag_net_amount
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON dd.d_date_sk = wp.wp_creation_date_sk
    WHERE dd.d_year = 2002
      AND s.s_state = 'CA'
      AND cd.cd_gender = 'M'
      AND cd.cd_purchase_estimate >= 2000
      AND ss.ss_quantity > 1
  ),
  returns_pre AS (
    SELECT
      cr.cr_order_number AS order_number,
      dd.d_year,
      NULL AS s_store_id,
      NULL AS s_state,
      cd.cd_gender,
      cd.cd_purchase_estimate,
      cr.cr_return_amount AS net_amount,
      NULL AS wp_url,
      ROW_NUMBER() OVER (PARTITION BY cr.cr_refunded_customer_sk ORDER BY cr.cr_return_amount DESC) AS rn,
      NULL AS lag_net_amount
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE dd.d_year = 2002
      AND cr.cr_return_amount > 100
      AND cr.cr_return_quantity > 0
      AND cd.cd_gender = 'M'
  ),
  intersect_orders AS (
    SELECT order_number FROM sales_pre
    INTERSECT
    SELECT order_number FROM returns_pre
  ),
  sales_top AS (
    SELECT *
    FROM sales_pre
    WHERE rn <= 5
      AND order_number IN (SELECT order_number FROM intersect_orders)
  ),
  returns_top AS (
    SELECT *
    FROM returns_pre
    WHERE rn <= 5
      AND order_number IN (SELECT order_number FROM intersect_orders)
  )
SELECT
  order_number,
  d_year,
  s_store_id,
  s_state,
  cd_gender,
  cd_purchase_estimate,
  net_amount,
  wp_url,
  rn,
  lag_net_amount
FROM sales_top
UNION DISTINCT
SELECT
  order_number,
  d_year,
  s_store_id,
  s_state,
  cd_gender,
  cd_purchase_estimate,
  net_amount,
  wp_url,
  rn,
  lag_net_amount
FROM returns_top
ORDER BY d_year DESC, net_amount DESC
LIMIT 100
