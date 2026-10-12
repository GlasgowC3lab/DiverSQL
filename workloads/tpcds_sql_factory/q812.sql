WITH discount_data AS (
  SELECT
    cp.cp_type,
    p.p_purpose,
    cs.cs_ext_discount_amt AS discount_amt,
    cs.cs_order_number AS transaction_id
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE cp.cp_type = 'Catalog'
  UNION ALL
  SELECT
    'Web' AS cp_type,
    p.p_purpose,
    ws.ws_ext_discount_amt AS discount_amt,
    ws.ws_order_number AS transaction_id
  FROM web_sales ws
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE ws.ws_ext_discount_amt > 0
),
aggregated AS (
  SELECT
    cp_type,
    p_purpose,
    SUM(discount_amt) AS total_discount,
    COUNT(*) AS txn_count,
    AVG(discount_amt) AS avg_discount,
    MAX(discount_amt) AS max_discount
  FROM discount_data
  GROUP BY cp_type, p_purpose
)
SELECT
  cp_type,
  p_purpose,
  total_discount,
  txn_count,
  avg_discount,
  max_discount,
  total_discount * 0.1 AS ten_percent_of_total,
  SUM(total_discount) OVER (PARTITION BY cp_type) AS total_by_type
FROM aggregated
WHERE txn_count >= 10
ORDER BY total_by_type DESC, cp_type
