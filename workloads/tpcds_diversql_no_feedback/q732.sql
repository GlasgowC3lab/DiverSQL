WITH all_data AS (
   SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_ship_date_sk,
      cs.cs_bill_customer_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_ship_customer_sk,
      cs.cs_ship_hdemo_sk,
      cs.cs_call_center_sk,
      cs.cs_ship_mode_sk,
      cs.cs_item_sk,
      cs.cs_promo_sk,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_return_amount,
      cr.cr_net_loss,
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_store_sk,
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_quantity,
      ws.ws_net_paid,
      ws.ws_net_profit,
      d_cs.d_year,
      i.i_brand,
      i.i_category,
      cc.cc_company,
      sm.sm_type,
      s.s_state,
      wsite.web_country,
      t_cs.t_am_pm,
      hd_bill.hd_income_band_sk
   FROM catalog_sales cs
   JOIN date_dim d_cs               ON cs.cs_sold_date_sk = d_cs.d_date_sk
   JOIN time_dim t_cs               ON cs.cs_sold_time_sk = t_cs.t_time_sk
   JOIN call_center cc             ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm               ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i                     ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p                ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer cust_bill         ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
   JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
   JOIN customer cust_ship         ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
   JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
   JOIN catalog_returns cr         ON cr.cr_order_number = cs.cs_order_number
   JOIN date_dim d_cr               ON cr.cr_returned_date_sk = d_cr.d_date_sk
   JOIN time_dim t_cr               ON cr.cr_returned_time_sk = t_cr.t_time_sk
   JOIN store_returns sr           ON sr.sr_item_sk = cs.cs_item_sk
   JOIN store s                    ON sr.sr_store_sk = s.s_store_sk
   JOIN date_dim d_sr              ON sr.sr_returned_date_sk = d_sr.d_date_sk
   JOIN time_dim t_sr              ON sr.sr_return_time_sk = t_sr.t_time_sk
   JOIN web_sales ws               ON ws.ws_item_sk = cs.cs_item_sk
   JOIN date_dim d_ws              ON ws.ws_sold_date_sk = d_ws.d_date_sk
   JOIN time_dim t_ws              ON ws.ws_sold_time_sk = t_ws.t_time_sk
   JOIN web_site wsite             ON ws.ws_web_site_sk = wsite.web_site_sk
   JOIN income_band ib             ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
   JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
   JOIN customer cust_refund       ON cr.cr_refunded_customer_sk = cust_refund.c_customer_sk
   JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
   WHERE d_cs.d_year = 2001
     AND i.i_brand = 'Brand#12'
     AND cc.cc_company = 2
     AND sm.sm_type = 'AIR'
     AND wsite.web_country = 'United States'
     AND t_cs.t_am_pm = 'PM'
     AND cs.cs_quantity > 5
     AND cr.cr_net_loss > 100
     AND ws.ws_quantity >= 2
),
sub1 AS (
   SELECT cust_bill.c_customer_sk AS cust_id
   FROM all_data ad
   JOIN customer cust_bill ON ad.cs_bill_customer_sk = cust_bill.c_customer_sk
   WHERE ad.i_category = 'Electronics'
),
sub2 AS (
   SELECT cust_ship.c_customer_sk AS cust_id
   FROM all_data ad
   JOIN customer cust_ship ON ad.cs_ship_customer_sk = cust_ship.c_customer_sk
   WHERE ad.ws_quantity > 3
),
intersect_customers AS (
   SELECT cust_id FROM sub1
   INTERSECT
   SELECT cust_id FROM sub2
)
SELECT
   ad.d_year,
   ad.s_state,
   COUNT(DISTINCT ic.cust_id) AS distinct_customer_cnt,
   SUM(ad.cs_net_paid) AS total_catalog_sales,
   SUM(ad.ws_net_paid) AS total_web_sales,
   AVG(ad.cr_return_amount) AS avg_return_amount,
   MIN(ad.sr_return_amt) AS min_store_return,
   MAX(ad.ws_net_profit) AS max_web_profit
FROM all_data ad
JOIN intersect_customers ic ON ad.cs_bill_customer_sk = ic.cust_id
GROUP BY ad.d_year, ad.s_state
ORDER BY total_catalog_sales DESC
LIMIT 100
