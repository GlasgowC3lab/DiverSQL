SELECT
  d_closed.d_year AS year,
  cc.cc_state || '-' || s.s_state AS state_pair,
  CASE WHEN cc.cc_tax_percentage > s.s_tax_percentage THEN 'CC>STORE' ELSE 'CC<=STORE' END AS tax_comparison,
  COUNT(DISTINCT cc.cc_call_center_sk) AS cc_cnt,
  COUNT(DISTINCT s.s_store_sk) AS store_cnt,
  AVG(date_diff('day', d_open.d_date, d_closed.d_date)) AS avg_cc_open_days,
  SUM(cc.cc_employees) AS total_cc_emp,
  SUM(s.s_number_employees) AS total_store_emp,
  AVG(cc.cc_tax_percentage) AS avg_cc_tax,
  AVG(s.s_tax_percentage) AS avg_store_tax,
  CASE
    WHEN AVG(s.s_tax_percentage) = 0 THEN NULL
    ELSE ROUND(AVG(cc.cc_tax_percentage) / AVG(s.s_tax_percentage), 2)
  END AS tax_ratio
FROM call_center cc
JOIN date_dim d_closed
  ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN date_dim d_open
  ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE cc.cc_state IS NOT NULL
  AND s.s_state IS NOT NULL
  AND cc.cc_tax_percentage IS NOT NULL
  AND s.s_tax_percentage IS NOT NULL
GROUP BY
  d_closed.d_year,
  cc.cc_state || '-' || s.s_state,
  CASE WHEN cc.cc_tax_percentage > s.s_tax_percentage THEN 'CC>STORE' ELSE 'CC<=STORE' END
HAVING COUNT(DISTINCT cc.cc_call_center_sk) > 5
   AND COUNT(DISTINCT s.s_store_sk) > 5
ORDER BY year DESC, cc_cnt DESC
LIMIT 100
