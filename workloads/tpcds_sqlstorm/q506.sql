WITH sr AS (
   SELECT d.d_year,
          d.d_moy,
          s.s_store_sk,
          s.s_store_name,
          SUM(ss.ss_net_profit) AS store_net_profit,
          SUM(ss.ss_quantity) AS store_quantity,
          COUNT(DISTINCT ss.ss_customer_sk) AS uniq_store_customers
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   WHERE d.d_year IN (1999, 2000)
   GROUP BY d.d_year, d.d_moy, s.s_store_sk, s.s_store_name
),
cr AS (
   SELECT d.d_year,
          d.d_moy,
          SUM(cs.cs_net_profit) AS catalog_net_profit,
          SUM(cs.cs_quantity) AS catalog_quantity,
          COUNT(DISTINCT cs.cs_bill_customer_sk) AS uniq_catalog_customers
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year IN (1999, 2000)
   GROUP BY d.d_year, d.d_moy
),
wr AS (
   SELECT d.d_year,
          d.d_moy,
          SUM(ws.ws_net_profit) AS web_net_profit,
          SUM(ws.ws_quantity) AS web_quantity,
          COUNT(DISTINCT ws.ws_bill_customer_sk) AS uniq_web_customers
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year IN (1999, 2000)
   GROUP BY d.d_year, d.d_moy
),
sr_ret AS (
   SELECT d.d_year,
          d.d_moy,
          SUM(sr.sr_net_loss) AS store_net_loss,
          SUM(sr.sr_return_quantity) AS store_return_qty
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE d.d_year IN (1999, 2000)
   GROUP BY d.d_year, d.d_moy
),
cr_ret AS (
   SELECT d.d_year,
          d.d_moy,
          SUM(crr.cr_net_loss) AS catalog_net_loss,
          SUM(crr.cr_return_quantity) AS catalog_return_qty
   FROM catalog_returns crr
   JOIN date_dim d ON crr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_year IN (1999, 2000)
   GROUP BY d.d_year, d.d_moy
),
wr_ret AS (
   SELECT d.d_year,
          d.d_moy,
          SUM(wr_ret.wr_net_loss) AS web_net_loss,
          SUM(wr_ret.wr_return_quantity) AS web_return_qty
   FROM web_returns wr_ret
   JOIN date_dim d ON wr_ret.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_year IN (1999, 2000)
   GROUP BY d.d_year, d.d_moy
),
combined AS (
   SELECT
      COALESCE(sr.d_year, cr.d_year, wr.d_year) AS year,
      COALESCE(sr.d_moy, cr.d_moy, wr.d_moy) AS month,
      COALESCE(sr.s_store_name, 'All Stores') AS store_name,
      COALESCE(sr.store_net_profit, 0) + COALESCE(cr.catalog_net_profit, 0) + COALESCE(wr.web_net_profit, 0) AS total_net_profit,
      COALESCE(sr.store_quantity, 0) + COALESCE(cr.catalog_quantity, 0) + COALESCE(wr.web_quantity, 0) AS total_quantity,
      COALESCE(sr.uniq_store_customers, 0) + COALESCE(cr.uniq_catalog_customers, 0) + COALESCE(wr.uniq_web_customers, 0) AS total_unique_customers,
      COALESCE(sr_ret.store_net_loss, 0) + COALESCE(cr_ret.catalog_net_loss, 0) + COALESCE(wr_ret.web_net_loss, 0) AS total_net_loss,
      (COALESCE(sr_ret.store_net_loss, 0) + COALESCE(cr_ret.catalog_net_loss, 0) + COALESCE(wr_ret.web_net_loss, 0)) * -1 AS total_return_recovery,
      (COALESCE(sr.store_net_profit, 0) + COALESCE(cr.catalog_net_profit, 0) + COALESCE(wr.web_net_profit, 0))
       - (COALESCE(sr_ret.store_net_loss, 0) + COALESCE(cr_ret.catalog_net_loss, 0) + COALESCE(wr_ret.web_net_loss, 0)) AS net_profit_after_returns
   FROM sr
   FULL OUTER JOIN cr ON sr.d_year = cr.d_year AND sr.d_moy = cr.d_moy
   FULL OUTER JOIN wr ON COALESCE(sr.d_year, cr.d_year) = wr.d_year AND COALESCE(sr.d_moy, cr.d_moy) = wr.d_moy
   FULL OUTER JOIN sr_ret ON COALESCE(sr.d_year, cr.d_year, wr.d_year) = sr_ret.d_year AND COALESCE(sr.d_moy, cr.d_moy, wr.d_moy) = sr_ret.d_moy
   FULL OUTER JOIN cr_ret ON COALESCE(sr.d_year, cr.d_year, wr.d_year) = cr_ret.d_year AND COALESCE(sr.d_moy, cr.d_moy, wr.d_moy) = cr_ret.d_moy
   FULL OUTER JOIN wr_ret ON COALESCE(sr.d_year, cr.d_year, wr.d_year) = wr_ret.d_year AND COALESCE(sr.d_moy, cr.d_moy, wr.d_moy) = wr_ret.d_moy
),
customer_ltv AS (
   SELECT
      c.c_customer_sk,
      c.c_customer_id,
      COALESCE(cs_ltv.catalog_net_profit, 0) + COALESCE(ss_ltv.store_net_profit, 0) + COALESCE(ws_ltv.web_net_profit, 0) AS lifetime_net_profit,
      COALESCE(cs_ltv.catalog_orders, 0) AS catalog_orders,
      COALESCE(ss_ltv.store_orders, 0) AS store_orders,
      COALESCE(ws_ltv.web_orders, 0) AS web_orders
   FROM customer c
   LEFT JOIN (
      SELECT cs.cs_bill_customer_sk AS cust_sk,
             SUM(cs.cs_net_profit) AS catalog_net_profit,
             COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
      FROM catalog_sales cs
      GROUP BY cs.cs_bill_customer_sk
   ) cs_ltv ON c.c_customer_sk = cs_ltv.cust_sk
   LEFT JOIN (
      SELECT ss.ss_customer_sk AS cust_sk,
             SUM(ss.ss_net_profit) AS store_net_profit,
             COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
      FROM store_sales ss
      GROUP BY ss.ss_customer_sk
   ) ss_ltv ON c.c_customer_sk = ss_ltv.cust_sk
   LEFT JOIN (
      SELECT ws.ws_bill_customer_sk AS cust_sk,
             SUM(ws.ws_net_profit) AS web_net_profit,
             COUNT(DISTINCT ws.ws_order_number) AS web_orders
      FROM web_sales ws
      GROUP BY ws.ws_bill_customer_sk
   ) ws_ltv ON c.c_customer_sk = ws_ltv.cust_sk
),
customer_profile AS (
   SELECT
      cl.c_customer_sk,
      cl.c_customer_id,
      cl.lifetime_net_profit,
      cd.cd_gender,
      cd.cd_marital_status,
      cd.cd_education_status,
      cd.cd_credit_rating,
      hd.hd_income_band_sk,
      hd.hd_buy_potential,
      hd.hd_dep_count,
      hd.hd_vehicle_count,
      ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cl.lifetime_net_profit DESC) AS gender_rank
   FROM customer_ltv cl
   JOIN customer c ON cl.c_customer_sk = c.c_customer_sk
   LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)

SELECT
   CONCAT(CAST(combined.year AS VARCHAR), '-', LPAD(CAST(combined.month AS VARCHAR), 2, '0')) AS year_month,
   combined.store_name,
   combined.total_quantity,
   combined.total_net_profit,
   combined.total_net_loss,
   combined.net_profit_after_returns,
   ROUND(combined.total_net_profit / NULLIF(combined.total_quantity, 0), 2) AS avg_profit_per_item,
   AVG(combined.total_net_profit) OVER (PARTITION BY combined.store_name ORDER BY combined.year, combined.month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_month_avg_profit,
   cp.c_customer_id,
   cp.lifetime_net_profit,
   cp.gender_rank
FROM combined
CROSS JOIN (
   SELECT *
   FROM customer_profile
   WHERE gender_rank <= 5
) cp
WHERE combined.year IS NOT NULL
ORDER BY year_month DESC, combined.store_name, cp.lifetime_net_profit DESC
