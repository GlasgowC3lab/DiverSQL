WITH first AS (
   SELECT cp.cp_department,
          sm.sm_carrier,
          p.p_promo_name,
          ca.ca_city,
          SUM(cs.cs_net_paid) AS total_catalog_sales,
          SUM(cr.cr_return_amount) AS total_catalog_returns,
          COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
          AVG(ss.ss_net_paid) AS avg_store_sales,
          SUM(sr.sr_net_loss) AS total_store_loss
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   WHERE ca.ca_city = 'New Hope'
     AND sm.sm_type = 'NEXT DAY'
     AND p.p_channel_dmail = 'Y'
     AND ib.ib_upper_bound > 50000
   GROUP BY cp.cp_department, sm.sm_carrier, p.p_promo_name, ca.ca_city
),
second AS (
   SELECT cp.cp_department,
          sm.sm_carrier,
          p.p_promo_name,
          ca.ca_city,
          SUM(cs.cs_net_paid) AS total_catalog_sales,
          SUM(cr.cr_return_amount) AS total_catalog_returns,
          COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
          AVG(ss.ss_net_paid) AS avg_store_sales,
          SUM(sr.sr_net_loss) AS total_store_loss
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
   JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
   WHERE ca.ca_city = 'Union'
     AND sm.sm_type = 'EXPRESS'
     AND p.p_channel_dmail = 'N'
     AND ib.ib_upper_bound <= 50000
   GROUP BY cp.cp_department, sm.sm_carrier, p.p_promo_name, ca.ca_city
)
SELECT *
FROM (
   SELECT * FROM first
   UNION
   SELECT * FROM second
) t
LIMIT 100
