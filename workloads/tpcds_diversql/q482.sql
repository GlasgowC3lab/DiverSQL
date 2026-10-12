WITH
  cs_agg AS (
    SELECT
      cs.cs_call_center_sk,
      SUM(cs.cs_net_paid) AS total_net_paid,
      COUNT(*) AS order_cnt,
      CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs.cs_call_center_sk
  ),
  call_center_filtered AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      cc.cc_city,
      CONCAT(cc.cc_city, ', ', cc.cc_state) AS location,
      regexp_extract(cc.cc_name, '(\\w+)', 1) AS first_word,
      CASE WHEN regexp_like(cc.cc_name, '^A.*') THEN 'StartsA' ELSE 'Other' END AS name_flag
    FROM call_center cc
    WHERE regexp_like(cc.cc_name, 'Center')
      AND cc.cc_city LIKE 'San_%'
  ),
  intersect_cc AS (
    SELECT call_center_sk FROM (
      SELECT cs.cs_call_center_sk AS call_center_sk
      FROM catalog_sales cs
      GROUP BY cs.cs_call_center_sk
      HAVING SUM(cs.cs_net_paid) > 50000
    )
    INTERSECT
    SELECT call_center_sk FROM (
      SELECT cs.cs_call_center_sk AS call_center_sk
      FROM catalog_sales cs
      JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
      WHERE regexp_like(p.p_promo_name, 'Summer')
      GROUP BY cs.cs_call_center_sk
      HAVING COUNT(*) > 5
    )
  )
SELECT
  ccf.cc_call_center_sk,
  ccf.cc_name,
  ccf.cc_city,
  ccf.location,
  ccf.first_word,
  ccf.name_flag,
  ca.total_net_paid,
  ca.sales_category,
  (SELECT AVG(cs_net_paid) FROM catalog_sales) AS overall_avg_net_paid
FROM call_center_filtered ccf
JOIN cs_agg ca ON ccf.cc_call_center_sk = ca.cs_call_center_sk
WHERE ccf.cc_call_center_sk NOT IN (
  SELECT cr.cr_call_center_sk
  FROM catalog_returns cr
  WHERE cr.cr_return_quantity > 0
)
  AND ccf.cc_call_center_sk IN (SELECT call_center_sk FROM intersect_cc)
ORDER BY ca.total_net_paid DESC
LIMIT 100
