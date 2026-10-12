/*
Goal: Compare the number of call centers opened vs closed per year for selected states and tax ranges, retaining all call‑center rows even when a matching date is missing, and combine the two results with a UNION ALL.
*/
SELECT
  d.d_year AS year,
  'OPENED' AS status,
  COUNT(c.cc_call_center_sk) AS cnt
FROM
  date_dim d
RIGHT OUTER JOIN
  call_center c
    ON d.d_date_sk = c.cc_open_date_sk
WHERE
  c.cc_state = 'NY'
  AND c.cc_tax_percentage >= 0.05
  AND d.d_date >= DATE '2000-01-01'
GROUP BY
  d.d_year,
  'OPENED'

UNION ALL

SELECT
  d.d_year AS year,
  'CLOSED' AS status,
  COUNT(c.cc_call_center_sk) AS cnt
FROM
  date_dim d
RIGHT OUTER JOIN
  call_center c
    ON d.d_date_sk = c.cc_closed_date_sk
WHERE
  c.cc_state = 'PA'
  AND c.cc_tax_percentage <= 0.07
  AND d.d_date >= DATE '2000-01-01'
GROUP BY
  d.d_year,
  'CLOSED'

ORDER BY
  year DESC,
  status
LIMIT 100
