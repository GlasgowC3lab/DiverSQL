WITH
  sales_keys AS (
    SELECT ss_ticket_number
    FROM store_sales
  ),
  return_keys AS (
    SELECT sr_ticket_number
    FROM store_returns
  ),
  sales_without_returns AS (
    SELECT ss_ticket_number AS ticket
    FROM store_sales
    EXCEPT
    SELECT sr_ticket_number
    FROM store_returns
  ),
  joined AS (
    SELECT
      d.d_year,
      cd.cd_education_status AS education_status,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_net_paid,
      cs.cs_net_paid,
      ws.ws_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
      AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
      AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE
      d.d_year = 2001
      AND cd.cd_education_status = 'College'
      AND hd.hd_buy_potential = '5000-9999'
      AND sm.sm_contract = 'fop0bcSd91J26IVpR'
      AND cc.cc_market_manager = 'Market Manager 1'
      AND p.p_discount_active = 'Y'
      AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_ticket_number = ss.ss_ticket_number
          AND sr.sr_returned_date_sk = ss.ss_sold_date_sk
      )
      AND ss.ss_quantity = (
        SELECT MAX(cs2.cs_quantity)
        FROM catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = ss.ss_sold_date_sk
      )
  )
SELECT
  d_year,
  education_status,
  COUNT(DISTINCT ss_ticket_number) AS sales_transactions,
  SUM(ss_net_paid) AS total_store_sales,
  SUM(cs_net_paid) AS total_catalog_sales,
  SUM(ws_net_paid) AS total_web_sales,
  AVG(ss_quantity) AS avg_store_quantity,
  MIN(ss_net_paid) AS min_store_net_paid,
  MAX(ss_net_paid) AS max_store_net_paid
FROM joined
JOIN sales_without_returns swr
  ON swr.ticket = joined.ss_ticket_number
GROUP BY d_year, education_status
ORDER BY total_store_sales DESC
LIMIT 100
