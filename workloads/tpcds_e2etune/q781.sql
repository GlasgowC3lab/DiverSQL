WITH catalog_metrics AS (
  SELECT
    cp.cp_department AS key,
    w.w_warehouse_name AS location,
    SUM(cs.cs_net_paid_inc_tax) AS total_sales_amount,
    SUM(COALESCE(cr.cr_return_amt_inc_tax, 0)) AS total_return_amount,
    SUM(cs.cs_net_profit) AS total_sales_profit,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
    'catalog' AS source
  FROM catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
   AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   AND cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE cp.cp_type = 'monthly'
    AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2450996
  GROUP BY cp.cp_department, w.w_warehouse_name
  HAVING SUM(cs.cs_net_paid_inc_tax) > 1000
),
store_metrics AS (
  SELECT
    CAST(ss.ss_store_sk AS varchar) AS key,
    CAST(NULL AS varchar) AS location,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales_amount,
    SUM(COALESCE(sr.sr_return_amt_inc_tax, 0)) AS total_return_amount,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    'store' AS source
  FROM store_sales ss
  JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2450996
  GROUP BY ss.ss_store_sk
  HAVING SUM(ss.ss_net_paid_inc_tax) > 1000
)
SELECT
  source,
  key,
  location,
  total_sales_amount,
  total_return_amount,
  (total_sales_profit - total_return_loss) AS net_contribution,
  CASE WHEN total_sales_amount = 0 THEN 0
       ELSE total_return_amount / total_sales_amount END AS return_rate,
  RANK() OVER (PARTITION BY source ORDER BY (total_sales_profit - total_return_loss) DESC) AS rank_within_source
FROM (
  SELECT * FROM catalog_metrics
  UNION ALL
  SELECT * FROM store_metrics
) AS combined
ORDER BY source, rank_within_source
LIMIT 100
