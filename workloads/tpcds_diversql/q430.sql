WITH
  ct_sales AS (
    SELECT
      cs_bill_customer_sk,
      SUM(cs_net_paid) AS cat_net_paid,
      COUNT(DISTINCT cs_order_number) AS cat_order_cnt
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY cs_bill_customer_sk
  ),
  ws_sales AS (
    SELECT
      ws_bill_customer_sk,
      SUM(ws_net_paid) AS web_net_paid,
      COUNT(DISTINCT ws_order_number) AS web_order_cnt
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY ws_bill_customer_sk
  ),
  common_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    INTERSECT
    SELECT ws_order_number
    FROM web_sales
  ),
  orders_no_return AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
  ),
  inv_wh_full AS (
    SELECT *
    FROM inventory
    FULL OUTER JOIN warehouse
      ON inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
  ),
  main_join AS (
    SELECT
      c.c_customer_sk,
      c.c_customer_id,
      c.c_first_name,
      c.c_last_name,
      cd.cd_gender            AS gender,
      hd.hd_vehicle_count,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cp.cp_department        AS department,
      p.p_promo_name          AS promo_name,
      sm.sm_type              AS ship_type,
      cr.cr_return_amount,
      sr.sr_store_credit,
      r.r_reason_desc,
      wp.wp_url,
      ct.cat_net_paid,
      ws_s.web_net_paid,
      (COALESCE(ct.cat_net_paid, 0) + COALESCE(ws_s.web_net_paid, 0)) AS total_spend,
      CASE
        WHEN COALESCE(ct.cat_net_paid, 0) + COALESCE(ws_s.web_net_paid, 0) > 10000 THEN 'HIGH'
        WHEN COALESCE(ct.cat_net_paid, 0) + COALESCE(ws_s.web_net_paid, 0) > 5000  THEN 'MEDIUM'
        ELSE 'LOW'
      END AS spend_category,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(ct.cat_net_paid, 0) + COALESCE(ws_s.web_net_paid, 0) DESC) AS spend_rank,
      inv.inv_quantity_on_hand,
      inv.inv_item_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN ct_sales ct ON c.c_customer_sk = ct.cs_bill_customer_sk
    LEFT JOIN ws_sales ws_s ON c.c_customer_sk = ws_s.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN inv_wh_full inv ON w.w_warehouse_sk = inv.w_warehouse_sk
    LEFT JOIN common_orders co ON cs.cs_order_number = co.cs_order_number
    LEFT JOIN orders_no_return nor ON cs.cs_order_number = nor.cs_order_number
    WHERE c.c_birth_year BETWEEN 1950 AND 1965
      AND cd.cd_purchase_estimate > 5000
      AND hd.hd_vehicle_count > 1
      AND p.p_discount_active = 'Y'
      AND cp.cp_department = 'Books'
      AND ib.ib_upper_bound <= 100000
      AND co.cs_order_number IS NOT NULL
      AND nor.cs_order_number IS NULL
  )
SELECT
  c_customer_id,
  c_first_name,
  c_last_name,
  gender,
  hd_vehicle_count,
  spend_category,
  total_spend,
  spend_rank,
  department,
  promo_name,
  ship_type,
  cr_return_amount,
  sr_store_credit,
  r_reason_desc,
  wp_url,
  inv_quantity_on_hand,
  inv_item_sk
FROM main_join
WHERE spend_rank <= 10
ORDER BY total_spend DESC
LIMIT 100
