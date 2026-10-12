WITH discount_data AS (
  SELECT
    cp.cp_type,
    p.p_purpose,
    cs.cs_ext_discount_amt AS discount_amt,
    cs.cs_order_number AS transaction_id
  FROM catalog_sales cs
  INNER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  INNER JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  UNION ALL
  SELECT
    'Web' AS cp_type,
    p.p_purpose,
    ws.ws_ext_discount_amt AS discount_amt,
    ws.ws_order_number AS transaction_id
  FROM web_sales ws
  INNER JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
),
aggregated AS (
  SELECT
    cp_type,
    p_purpose,
    SUM(discount_amt) AS total_discount,
    COUNT(DISTINCT transaction_id) AS transaction_cnt,
    CASE
      WHEN SUM(discount_amt) > 5000 THEN 'High'
      WHEN SUM(discount_amt) > 1000 THEN 'Medium'
      ELSE 'Low'
    END AS discount_category
  FROM discount_data
  GROUP BY cp_type, p_purpose
)
SELECT
  cp_type,
  p_purpose,
  total_discount,
  transaction_cnt,
  total_discount / transaction_cnt AS avg_discount_per_txn,
  discount_category,
  SUM(total_discount) OVER (PARTITION BY cp_type ORDER BY p_purpose
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_discount_by_type
FROM aggregated
ORDER BY cp_type, total_discount DESC
