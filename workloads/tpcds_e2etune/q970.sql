WITH ss_store AS (
  SELECT
    s.s_store_sk,
    s.s_store_name,
    s.s_city,
    s.s_state,
    SUM(ss.ss_net_paid_inc_tax) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_transactions,
    RANK() OVER (ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS sales_rank
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
  GROUP BY s.s_store_sk, s.s_store_name, s.s_city, s.s_state
),
cr_reason AS (
  SELECT
    r.r_reason_sk,
    r.r_reason_desc,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_transactions,
    RANK() OVER (ORDER BY SUM(cr.cr_return_amount) DESC) AS return_rank
  FROM catalog_returns cr
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
  GROUP BY r.r_reason_sk, r.r_reason_desc
)
SELECT
  ss.s_store_name,
  ss.s_city,
  ss.s_state,
  ss.total_sales,
  ss.total_profit,
  ss.sales_transactions,
  ss.sales_rank,
  cr.r_reason_desc,
  cr.total_return_amount,
  cr.total_net_loss,
  cr.return_transactions,
  cr.return_rank,
  (cr.total_return_amount / NULLIF(ss.total_sales, 0)) AS return_to_sales_ratio
FROM ss_store ss
CROSS JOIN cr_reason cr
WHERE ss.sales_rank <= 10
ORDER BY return_to_sales_ratio DESC
LIMIT 50
