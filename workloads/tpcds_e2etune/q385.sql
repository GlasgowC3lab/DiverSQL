WITH store_metrics AS (
  SELECT
    s.s_state AS region,
    s.s_city AS subregion,
    'store' AS channel,
    SUM(ss.ss_net_paid) AS total_amount,
    SUM(ss.ss_net_profit) AS metric_value,
    COUNT(*) AS transaction_count
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451088
    AND s.s_country = 'United States'
  GROUP BY s.s_state, s.s_city
),
catalog_metrics AS (
  SELECT
    cp.cp_department AS region,
    cp.cp_type AS subregion,
    'catalog' AS channel,
    SUM(cr.cr_return_amount) AS total_amount,
    SUM(cr.cr_net_loss) AS metric_value,
    COUNT(*) AS transaction_count
  FROM catalog_returns cr
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE cp.cp_start_date_sk >= 2450815
    AND cp.cp_end_date_sk <= 2451088
    AND cp.cp_type = 'monthly'
  GROUP BY cp.cp_department, cp.cp_type
)
SELECT
  region,
  subregion,
  channel,
  total_amount,
  metric_value,
  transaction_count,
  RANK() OVER (PARTITION BY channel ORDER BY total_amount DESC) AS amount_rank
FROM (
  SELECT * FROM store_metrics
  UNION ALL
  SELECT * FROM catalog_metrics
) AS combined
WHERE total_amount > 10000
ORDER BY channel, amount_rank
LIMIT 200
