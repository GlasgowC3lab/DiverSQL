WITH first AS (
  SELECT
    cc.cc_state,
    cp.cp_type,
    sm.sm_carrier,
    td.t_meal_time,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    ss.ss_ticket_number,
    gen.dummy
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2 AS dummy) gen
  WHERE cc.cc_state = 'CA'
    AND cp.cp_type = 'monthly'
    AND sm.sm_carrier = 'DHL'
    AND td.t_meal_time = 'lunch'
    AND ss.ss_quantity > 5
),
second AS (
  SELECT
    cc.cc_state,
    cp.cp_type,
    sm.sm_carrier,
    td.t_meal_time,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    ss.ss_ticket_number,
    gen.dummy
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  CROSS JOIN (SELECT 1 AS dummy UNION ALL SELECT 2 AS dummy) gen
  WHERE cc.cc_state = 'TX'
    AND cp.cp_type = 'quarterly'
    AND sm.sm_carrier = 'USPS'
    AND td.t_meal_time = 'dinner'
    AND ss.ss_quantity > 3
),
unioned AS (
  SELECT
    cc_state,
    cp_type,
    sm_carrier,
    t_meal_time,
    ib_lower_bound,
    ib_upper_bound,
    dummy,
    COUNT(DISTINCT ss_ticket_number) AS order_cnt,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_ext_sales_price) AS avg_sales,
    MIN(ss_net_profit) AS min_profit,
    MAX(ss_net_profit) AS max_profit
  FROM (
    SELECT * FROM first
    UNION
    SELECT * FROM second
  ) u
  GROUP BY
    cc_state,
    cp_type,
    sm_carrier,
    t_meal_time,
    ib_lower_bound,
    ib_upper_bound,
    dummy
)
SELECT
  ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num,
  cc_state,
  cp_type,
  sm_carrier,
  t_meal_time,
  ib_lower_bound,
  ib_upper_bound,
  order_cnt,
  total_sales,
  avg_sales,
  min_profit,
  max_profit
FROM unioned
ORDER BY total_sales DESC
LIMIT 100
