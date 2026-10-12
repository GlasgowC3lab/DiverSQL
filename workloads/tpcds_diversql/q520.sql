WITH
  sales AS (
    SELECT
      cs.cs_order_number,
      cs.cs_net_profit,
      cc.cc_name,
      sm.sm_type,
      td.t_hour,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      ca.ca_city,
      cd.cd_gender
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE EXISTS (
      SELECT 1 FROM web_sales ws
      WHERE ws.ws_order_number = cs.cs_order_number
        AND ws.ws_quantity > 0
    )
  ),
  returns AS (
    SELECT
      cr.cr_order_number,
      cr.cr_net_loss,
      cc_ret.cc_name AS cc_name_ret,
      sm_ret.sm_type AS sm_type_ret,
      td_ret.t_hour AS return_hour,
      ib_ret.ib_lower_bound,
      ib_ret.ib_upper_bound,
      ca_ret.ca_city,
      cd_ret.cd_gender
    FROM catalog_returns cr
    JOIN call_center cc_ret ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
    JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    JOIN time_dim td_ret ON cr.cr_returned_time_sk = td_ret.t_time_sk
    JOIN household_demographics hd_ret ON cr.cr_refunded_hdemo_sk = hd_ret.hd_demo_sk
    JOIN income_band ib_ret ON hd_ret.hd_income_band_sk = ib_ret.ib_income_band_sk
    JOIN item i_ret ON cr.cr_item_sk = i_ret.i_item_sk
    JOIN customer_address ca_ret ON cr.cr_refunded_addr_sk = ca_ret.ca_address_sk
    JOIN customer_demographics cd_ret ON cr.cr_refunded_cdemo_sk = cd_ret.cd_demo_sk
  ),
  web AS (
    SELECT
      ws.ws_order_number,
      ws.ws_net_paid,
      sm_ws.sm_type AS ship_mode_type,
      td_ws.t_hour,
      ib_ws.ib_lower_bound,
      ib_ws.ib_upper_bound,
      wp.wp_type AS page_type,
      ca_ws.ca_city,
      cd_ws.cd_gender
    FROM web_sales ws
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
    JOIN household_demographics hd_ws ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
    JOIN income_band ib_ws ON hd_ws.hd_income_band_sk = ib_ws.ib_income_band_sk
    JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca_ws ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
  ),
  store AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_net_loss,
      td_sr.t_hour,
      ib_sr.ib_lower_bound,
      ib_sr.ib_upper_bound,
      r.r_reason_desc,
      ca_sr.ca_city,
      cd_sr.cd_gender
    FROM store_returns sr
    JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN item i_sr ON sr.sr_item_sk = i_sr.i_item_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN income_band ib_sr ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
  ),
  order_intersect AS (
    SELECT cr.cr_order_number AS order_num FROM catalog_returns cr
    INTERSECT
    SELECT sr.sr_ticket_number AS order_num FROM store_returns sr
  ),
  reason_cross AS (
    SELECT r.r_reason_id, v.year
    FROM reason r
    CROSS JOIN (VALUES 2020, 2021) AS v(year)
  ),
  combined_sales_returns AS (
    SELECT
      COALESCE(s.cs_order_number, r.cr_order_number) AS order_number,
      COALESCE(s.cc_name, r.cc_name_ret) AS call_center_name,
      COALESCE(s.sm_type, r.sm_type_ret) AS ship_mode_type,
      COALESCE(s.t_hour, r.return_hour) AS hour,
      COALESCE(s.ib_lower_bound, r.ib_lower_bound) AS income_lower,
      COALESCE(s.ib_upper_bound, r.ib_upper_bound) AS income_upper,
      s.cs_net_profit,
      r.cr_net_loss,
      s.ca_city,
      s.cd_gender
    FROM sales s
    FULL OUTER JOIN returns r ON s.cs_order_number = r.cr_order_number
    WHERE COALESCE(s.cs_order_number, r.cr_order_number) IN (SELECT order_num FROM order_intersect)
  )
SELECT
  csr.call_center_name,
  csr.ship_mode_type,
  csr.hour,
  csr.income_lower,
  csr.income_upper,
  SUM(COALESCE(csr.cs_net_profit, 0) - COALESCE(csr.cr_net_loss, 0)) AS net_amount,
  COUNT(DISTINCT csr.order_number) AS order_cnt,
  rc.r_reason_id,
  rc.year
FROM combined_sales_returns csr
CROSS JOIN reason_cross rc
LEFT JOIN web w ON csr.order_number = w.ws_order_number
LEFT JOIN store st ON csr.order_number = st.sr_ticket_number
GROUP BY CUBE (csr.call_center_name, csr.ship_mode_type, csr.hour, csr.income_lower, csr.income_upper, rc.r_reason_id, rc.year)
ORDER BY net_amount DESC
LIMIT 100
