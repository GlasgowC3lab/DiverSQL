WITH
store_sales_agg AS (
 SELECT
   ss_sold_date_sk AS date_sk,
   ss_store_sk,
   SUM(ss_net_paid) AS store_sales_net,
   SUM(ss_net_profit) AS store_profit,
   COUNT(*) AS store_txn_cnt,
   AVG(ss_net_paid) AS store_avg_paid
 FROM store_sales
 GROUP BY ss_sold_date_sk, ss_store_sk
),
web_sales_agg AS (
 SELECT
   ws_sold_date_sk AS date_sk,
   ws_web_page_sk,
   SUM(ws_net_paid) AS web_sales_net,
   SUM(ws_net_profit) AS web_profit,
   COUNT(*) AS web_txn_cnt,
   AVG(ws_net_paid) AS web_avg_paid
 FROM web_sales
 GROUP BY ws_sold_date_sk, ws_web_page_sk
),
catalog_sales_max_price AS (
 SELECT
   cs_sold_date_sk AS date_sk,
   MAX(cs_sales_price) AS max_sales_price
 FROM catalog_sales
 GROUP BY cs_sold_date_sk
),
returns_raw AS (
 SELECT cr_returned_date_sk AS date_sk, cr_net_loss AS loss FROM catalog_returns
 UNION ALL
 SELECT sr_returned_date_sk AS date_sk, sr_net_loss FROM store_returns
 UNION ALL
 SELECT wr_returned_date_sk AS date_sk, wr_net_loss FROM web_returns
),
returns_agg AS (
 SELECT
   date_sk,
   SUM(loss) AS total_return_loss,
   COUNT(*) AS total_return_cnt
 FROM returns_raw
 GROUP BY date_sk
),
daily_combined AS (
 SELECT
   d.d_date,
   d.d_date_sk,
   d.d_year,
   COALESCE(ss.store_sales_net, 0) + COALESCE(ws.web_sales_net, 0) AS total_sales_net,
   COALESCE(ss.store_profit, 0) + COALESCE(ws.web_profit, 0) AS total_profit,
   COALESCE(r.total_return_loss, 0) AS total_return_loss,
   COALESCE(ss.store_txn_cnt, 0) + COALESCE(ws.web_txn_cnt, 0) AS total_transactions,
   (COALESCE(ss.store_sales_net, 0) + COALESCE(ws.web_sales_net, 0) - COALESCE(r.total_return_loss, 0)) AS net_after_returns,
   CASE WHEN (COALESCE(ss.store_sales_net, 0) + COALESCE(ws.web_sales_net, 0) - COALESCE(r.total_return_loss, 0)) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
   CONCAT(COALESCE(s.s_store_name, 'UNKNOWN'), ' - ', COALESCE(s.s_state, 'N/A')) AS store_label,
   ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY (COALESCE(ss.store_sales_net,0) + COALESCE(ws.web_sales_net,0) - COALESCE(r.total_return_loss,0)) DESC) AS yearly_rank,
   (COALESCE(ss.store_sales_net,0) + COALESCE(ws.web_sales_net,0) - COALESCE(r.total_return_loss,0))
     / NULLIF(COALESCE(ss.store_txn_cnt,0) + COALESCE(ws.web_txn_cnt,0), 0) AS avg_net_per_txn,
   (SELECT MAX(cs_sales_price) FROM catalog_sales cs WHERE cs.cs_sold_date_sk = d.d_date_sk) AS correlated_max_cs_price,
   COALESCE(msp.max_sales_price, 0) AS precomputed_max_cs_price
 FROM date_dim d
 LEFT JOIN store_sales_agg ss ON ss.date_sk = d.d_date_sk
 LEFT JOIN web_sales_agg ws ON ws.date_sk = d.d_date_sk
 LEFT JOIN returns_agg r ON r.date_sk = d.d_date_sk
 LEFT JOIN store s ON s.s_store_sk = ss.ss_store_sk
 LEFT JOIN catalog_sales_max_price msp ON msp.date_sk = d.d_date_sk
 WHERE d.d_year BETWEEN 1999 AND 2002
),
call_center_agg AS (
 SELECT
   cc.cc_call_center_sk,
   SUM(COALESCE(cs.cs_net_paid_inc_tax,0)) AS cc_sales_inc_tax,
   SUM(COALESCE(cs.cs_ext_discount_amt,0)) AS cc_discount_total,
   COUNT(*) AS cc_txn_cnt,
   MAX(cc.cc_manager) AS cc_manager
 FROM catalog_sales cs
 JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
 GROUP BY cc.cc_call_center_sk
),
call_center_daily AS (
 SELECT
   d.d_date,
   d.d_date_sk,
   COALESCE(cc.cc_sales_inc_tax,0) AS cc_sales_inc_tax,
   COALESCE(cc.cc_discount_total,0) AS cc_discount_total,
   COALESCE(cc.cc_txn_cnt,0) AS cc_txn_cnt,
   cc.cc_manager
 FROM date_dim d
 LEFT JOIN call_center_agg cc ON (d.d_date_sk % 10) = (cc.cc_call_center_sk % 10)
 WHERE d.d_year BETWEEN 1999 AND 2002
)

SELECT
  dc.d_date,
  dc.total_sales_net,
  dc.total_profit,
  dc.total_return_loss,
  dc.net_after_returns,
  dc.profit_flag,
  dc.store_label,
  dc.yearly_rank,
  ROUND(dc.avg_net_per_txn,2) AS avg_net_per_txn,
  dc.correlated_max_cs_price,
  dc.precomputed_max_cs_price,
  ccd.cc_sales_inc_tax,
  ccd.cc_discount_total,
  ccd.cc_txn_cnt,
  CASE
    WHEN ccd.cc_txn_cnt > 0 THEN ccd.cc_sales_inc_tax / NULLIF(ccd.cc_txn_cnt,0)
    ELSE NULL
  END AS cc_avg_sale_per_txn,
  CASE
    WHEN dc.profit_flag = 'POS' AND ccd.cc_discount_total > 0 THEN 'GOOD_WITH_DISCOUNT'
    WHEN dc.profit_flag = 'NEG' AND ccd.cc_discount_total IS NULL THEN 'BAD_NO_DISCOUNT'
    ELSE 'MIXED'
  END AS overall_assessment,
  COUNT(*) OVER (PARTITION BY dc.d_year) AS days_in_year,
  MAX(dc.avg_net_per_txn) OVER (PARTITION BY dc.d_year) AS max_avg_net_per_txn_year,
  MIN(dc.avg_net_per_txn) OVER (PARTITION BY dc.d_year) AS min_avg_net_per_txn_year,
  ROW_NUMBER() OVER (PARTITION BY dc.d_year ORDER BY dc.net_after_returns DESC) AS rank_in_year_by_net
FROM daily_combined dc
FULL OUTER JOIN call_center_daily ccd ON dc.d_date = ccd.d_date
WHERE EXISTS (
  SELECT 1 FROM catalog_returns cr
  WHERE cr.cr_returned_date_sk = dc.d_date_sk
    AND cr.cr_net_loss IS NOT NULL
)
   OR dc.profit_flag = 'NEG'
ORDER BY dc.d_date DESC
LIMIT 100
