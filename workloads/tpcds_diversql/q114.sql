WITH base_events AS (
   SELECT
     td.t_time_sk,
     td.t_hour,
     cc.cc_name               AS cc_name,
     cp.cp_department         AS cp_department,
     p.p_promo_name           AS p_promo_name,
     sm.sm_type               AS sm_type,
     w.w_warehouse_name       AS w_warehouse_name,
     ib.ib_lower_bound        AS ib_lower_bound,
     ib.ib_upper_bound        AS ib_upper_bound,
     cd.cd_gender             AS cd_gender,
     cd.cd_marital_status     AS cd_marital_status,
     hd.hd_buy_potential      AS hd_buy_potential,
     r.r_reason_desc          AS r_reason_desc,
     st.s_store_name          AS s_store_name,
     ca.ca_city               AS ca_city,
     i.inv_quantity_on_hand  AS inv_quantity_on_hand,
     cs.cs_order_number,
     cs.cs_ext_sales_price,
     cs.cs_net_profit,
     ws.ws_order_number,
     ws.ws_ext_sales_price,
     ws.ws_net_profit,
     sr.sr_ticket_number,
     sr.sr_return_amt,
     sr.sr_net_loss,
     ROW_NUMBER() OVER (ORDER BY td.t_time_sk) AS global_row_num
   FROM time_dim td
   JOIN catalog_sales cs ON cs.cs_sold_time_sk = td.t_time_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
   JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
   JOIN store st ON sr.sr_store_sk = st.s_store_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN (
     SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)
   ) i ON i.inv_warehouse_sk = w.w_warehouse_sk
   WHERE cd.cd_marital_status = 'M'
     AND ib.ib_upper_bound < 80000
     AND cc.cc_rec_start_date >= DATE '2001-01-01'
),

summed_events AS (
   SELECT
     s_store_name,
     cc_name,
     cp_department,
     SUM(cs_ext_sales_price)   AS catalog_sales_sum,
     SUM(ws_ext_sales_price)   AS web_sales_sum,
     SUM(sr_return_amt)        AS returns_sum,
     AVG(inv_quantity_on_hand) AS avg_inventory,
     COUNT(DISTINCT t_hour)    AS distinct_hours
   FROM base_events
   GROUP BY s_store_name, cc_name, cp_department
)

SELECT
  s_store_name,
  cc_name,
  cp_department,
  catalog_sales_sum,
  web_sales_sum,
  returns_sum,
  avg_inventory,
  distinct_hours
FROM summed_events
WHERE catalog_sales_sum > 100000
  AND avg_inventory > 500
ORDER BY catalog_sales_sum DESC
LIMIT 100
