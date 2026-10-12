WITH aggregated AS (
   SELECT
      s.s_store_sk AS store_sk,
      s.s_store_name AS store_name,
      s.s_state AS state,
      d.d_year AS year,
      SUM(ss.ss_net_paid) AS store_sales_net_paid,
      SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
      SUM(ss.ss_net_profit) AS store_profit,
      SUM(cs.cs_net_profit) AS catalog_profit
   FROM tpcds.date_dim d
   JOIN tpcds.store s
     ON s.s_closed_date_sk = d.d_date_sk
   JOIN tpcds.store_sales ss
     ON ss.ss_sold_date_sk = d.d_date_sk
    AND ss.ss_store_sk = s.s_store_sk
   JOIN tpcds.time_dim t
     ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN tpcds.customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   JOIN tpcds.store_returns sr
     ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_store_sk = s.s_store_sk
   JOIN tpcds.catalog_sales cs
     ON cs.cs_sold_date_sk = d.d_date_sk
    AND cs.cs_sold_time_sk = t.t_time_sk
   JOIN tpcds.catalog_returns cr
     ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN tpcds.call_center cc
     ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN tpcds.catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN tpcds.ship_mode sm
     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE d.d_year = 2001
     AND s.s_state = 'CO'
     AND cc.cc_company = 4
   GROUP BY s.s_store_sk, s.s_store_name, s.s_state, d.d_year
)
SELECT
   store_name,
   state,
   year,
   store_sales_net_paid,
   catalog_sales_net_paid,
   store_profit,
   catalog_profit,
   (store_profit + catalog_profit) AS total_profit,
   CASE WHEN (store_profit + catalog_profit) > 1000000 THEN 'HIGH' ELSE 'MEDIUM' END AS profit_category,
   ROW_NUMBER() OVER (PARTITION BY year ORDER BY (store_profit + catalog_profit) DESC) AS profit_rank
FROM aggregated
ORDER BY profit_rank
LIMIT 100
