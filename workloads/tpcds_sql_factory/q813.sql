WITH discount_data AS (
  SELECT
    cp.cp_type,
    p.p_purpose,
    cs.cs_ext_discount_amt AS discount_amt,
    cs.cs_order_number AS transaction_id,
    cs.cs_sold_time_sk AS sold_time_sk
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE cs.cs_ext_discount_amt IS NOT NULL
  UNION ALL
  SELECT
    'Web' AS cp_type,
    p.p_purpose,
    ws.ws_ext_discount_amt AS discount_amt,
    ws.ws_order_number AS transaction_id,
    ws.ws_sold_time_sk AS sold_time_sk
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE ws.ws_ext_discount_amt IS NOT NULL
),
aggregated AS (
  SELECT
    cp_type,
    p_purpose,
    SUM(discount_amt) AS total_discount,
    COUNT(DISTINCT transaction_id) AS txn_cnt,
    MIN(sold_time_sk) AS first_time,
    MAX(sold_time_sk) AS last_time
  FROM discount_data
  GROUP BY cp_type, p_purpose
)
SELECT
  cp_type,
  p_purpose,
  total_discount,
  txn_cnt,
  total_discount / NULLIF(txn_cnt,0) AS avg_discount,
  DATE_DIFF('day', FROM_UNIXTIME(first_time), FROM_UNIXTIME(last_time)) AS active_days,
  ROW_NUMBER() OVER (PARTITION BY cp_type ORDER BY total_discount DESC) AS rank_by_discount
FROM aggregated
WHERE total_discount > 2000
ORDER BY cp_type, rank_by_discount
