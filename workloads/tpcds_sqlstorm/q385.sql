WITH
store_sales_agg AS (
 SELECT
   d.d_year,
   s.s_state,
   SUM(ss.ss_net_profit) AS store_net_profit,
   SUM(ss.ss_ext_sales_price) AS store_sales,
   SUM(ss.ss_quantity) AS store_quantity,
   COUNT(*) AS store_txn_count
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 GROUP BY d.d_year, s.s_state
),
web_sales_agg AS (
 SELECT
   d.d_year,
   w.web_state,
   SUM(ws.ws_net_profit) AS web_net_profit,
   SUM(ws.ws_ext_sales_price) AS web_sales,
   SUM(ws.ws_quantity) AS web_quantity,
   COUNT(*) AS web_txn_count
 FROM web_sales ws
 JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
 JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
 GROUP BY d.d_year, w.web_state
),
catalog_sales_agg AS (
 SELECT
   d.d_year,
   cc.cc_state,
   SUM(cs.cs_net_profit) AS catalog_net_profit,
   SUM(cs.cs_ext_sales_price) AS catalog_sales,
   SUM(cs.cs_quantity) AS catalog_quantity,
   COUNT(*) AS catalog_txn_count
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
 GROUP BY d.d_year, cc.cc_state
),
returns_agg AS (
 SELECT
   d.d_year,
   COALESCE(cc.cc_state, s.s_state) AS state,
   SUM(cr.cr_return_amount) AS catalog_return_amount,
   SUM(sr.sr_return_amt) AS store_return_amount
 FROM date_dim d
 LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
 LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
 LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
 LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
 GROUP BY d.d_year, COALESCE(cc.cc_state, s.s_state)
),
store_top_customer AS (
 SELECT
   d.d_year AS year,
   s.s_state AS state,
   c.c_customer_id,
   SUM(ss.ss_net_paid) AS total_paid,
   ROW_NUMBER() OVER (PARTITION BY d.d_year, s.s_state ORDER BY SUM(ss.ss_net_paid) DESC) AS cust_rank
 FROM store_sales ss
 JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
 JOIN store s ON ss.ss_store_sk = s.s_store_sk
 JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
 GROUP BY d.d_year, s.s_state, c.c_customer_id
)
SELECT
  COALESCE(ssa.d_year, wsa.d_year, csa.d_year) AS year,
  COALESCE(ssa.s_state, wsa.web_state, csa.cc_state) AS state,
  COALESCE(ssa.store_sales, 0) + COALESCE(wsa.web_sales, 0) + COALESCE(csa.catalog_sales, 0) AS total_sales,
  COALESCE(ssa.store_net_profit, 0) + COALESCE(wsa.web_net_profit, 0) + COALESCE(csa.catalog_net_profit, 0) AS total_net_profit,
  COALESCE(rsa.catalog_return_amount, 0) + COALESCE(rsa.store_return_amount, 0) AS total_returns,
  CASE WHEN (COALESCE(ssa.store_sales, 0) + COALESCE(wsa.web_sales, 0) + COALESCE(csa.catalog_sales, 0)) = 0 THEN NULL
       ELSE (COALESCE(ssa.store_net_profit, 0) + COALESCE(wsa.web_net_profit, 0) + COALESCE(csa.catalog_net_profit, 0))
            / (COALESCE(ssa.store_sales, 0) + COALESCE(wsa.web_sales, 0) + COALESCE(csa.catalog_sales, 0)) END AS profit_margin,
  COALESCE(ssa.store_txn_count, 0) + COALESCE(wsa.web_txn_count, 0) + COALESCE(csa.catalog_txn_count, 0) AS total_txn_count,
  stc.c_customer_id AS top_customer_id,
  stc.total_paid AS top_customer_spent,
  ROW_NUMBER() OVER (PARTITION BY COALESCE(ssa.d_year, wsa.d_year, csa.d_year)
                     ORDER BY (COALESCE(ssa.store_net_profit, 0) + COALESCE(wsa.web_net_profit, 0) + COALESCE(csa.catalog_net_profit, 0)) DESC) AS state_rank
FROM store_sales_agg ssa
FULL OUTER JOIN web_sales_agg wsa
  ON ssa.d_year = wsa.d_year AND ssa.s_state = wsa.web_state
FULL OUTER JOIN catalog_sales_agg csa
  ON COALESCE(ssa.d_year, wsa.d_year) = csa.d_year
 AND COALESCE(ssa.s_state, wsa.web_state) = csa.cc_state
LEFT JOIN returns_agg rsa
  ON COALESCE(ssa.d_year, wsa.d_year, csa.d_year) = rsa.d_year
 AND COALESCE(ssa.s_state, wsa.web_state, csa.cc_state) = rsa.state
LEFT JOIN (
  SELECT year, state, c_customer_id, total_paid
  FROM store_top_customer
  WHERE cust_rank = 1
) stc
  ON COALESCE(ssa.d_year, wsa.d_year, csa.d_year) = stc.year
 AND COALESCE(ssa.s_state, wsa.web_state, csa.cc_state) = stc.state
WHERE (COALESCE(ssa.store_net_profit, 0) + COALESCE(wsa.web_net_profit, 0) + COALESCE(csa.catalog_net_profit, 0)) > 1000000
ORDER BY year, state_rank
LIMIT 100
