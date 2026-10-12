WITH sampled_cc AS (
  SELECT *
  FROM call_center
  TABLESAMPLE BERNOULLI (10)   -- sample 10% of call_center rows
),
cc_expanded AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_manager,
    hour_token,
    CASE
      WHEN regexp_like(cc.cc_manager, '^A.*') THEN 'A_Manager'
      ELSE 'Other_Manager'
    END AS manager_category
  FROM sampled_cc AS cc
  CROSS JOIN UNNEST(split(cc.cc_hours, ',')) AS t(hour_token)
)
SELECT
  ce.manager_category,
  i.i_category,
  COUNT(DISTINCT cs.cs_order_number) AS orders,
  SUM(cs.cs_net_paid) AS total_net_paid,
  SUM(CASE WHEN i.i_category = 'Electronics' THEN cs.cs_net_paid ELSE 0 END) AS electronics_net_paid,
  REGEXP_EXTRACT(i.i_product_name, '(\\d{3,})') AS product_code,
  MAX(ce.hour_token) AS sample_hour_token
FROM cc_expanded AS ce
JOIN catalog_sales cs
  ON ce.cc_call_center_sk = cs.cs_call_center_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
WHERE i.i_product_name LIKE '%Deluxe%'
  AND regexp_like(i.i_product_name, '^.*[A-Z]{2}[0-9]{2}.*$')
GROUP BY
  ce.manager_category,
  i.i_category,
  REGEXP_EXTRACT(i.i_product_name, '(\\d{3,})')
ORDER BY total_net_paid DESC
LIMIT 100
