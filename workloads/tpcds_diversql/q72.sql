WITH
  customers_a AS (
    SELECT c.c_customer_sk
    FROM store_sales ss
      JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
      JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
      JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
      JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
      JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
      JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
      JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
      JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE p.p_item_sk = 234655
      AND hd.hd_buy_potential = '5001-10000'
      AND t.t_shift = 'first'
      AND cc.cc_country = 'USA'
      AND w.w_state = 'CA'
      AND cd.cd_gender = 'M'
    GROUP BY c.c_customer_sk
  ),
  customers_b AS (
    SELECT c.c_customer_sk
    FROM store_sales ss
      JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
      JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
      JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
      JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
      JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
      JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
      JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
      JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
      JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE p.p_channel_demo = 'N'
      AND hd.hd_vehicle_count >= 2
      AND t.t_second BETWEEN 1 AND 10
      AND cc.cc_state = 'TX'
      AND w.w_gmt_offset = -6.00
      AND cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_sk
  ),
  common_customers AS (
    SELECT c_customer_sk FROM customers_a
    INTERSECT
    SELECT c_customer_sk FROM customers_b
  )
SELECT
  c.c_customer_id,
  COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
  SUM(ss.ss_ext_sales_price) AS total_sales,
  SUM(cr.cr_return_amount) AS total_returns,
  AVG(ss.ss_quantity) AS avg_quantity,
  MIN(ss.ss_sold_date_sk) AS first_sale_date_sk,
  MAX(sr.sr_returned_date_sk) AS last_return_date_sk
FROM common_customers cm
  JOIN customer c ON cm.c_customer_sk = c.c_customer_sk
  JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
  JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE p.p_item_sk = 234655
  AND hd.hd_buy_potential = '5001-10000'
  AND t.t_shift = 'first'
  AND cc.cc_country = 'USA'
  AND w.w_state = 'CA'
  AND cd.cd_gender = 'M'
GROUP BY c.c_customer_id
ORDER BY total_sales DESC
LIMIT 100
