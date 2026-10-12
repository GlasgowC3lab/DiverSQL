WITH q1 AS (
  SELECT
    td.t_sub_shift,
    w.w_city,
    SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE w.w_gmt_offset = -5.00
  GROUP BY CUBE (td.t_sub_shift, w.w_city)
),
q2 AS (
  SELECT
    td.t_sub_shift,
    w.w_city,
    SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  WHERE td.t_hour BETWEEN 0 AND 6
  GROUP BY CUBE (td.t_sub_shift, w.w_city)
)
SELECT
  t_sub_shift,
  w_city,
  total_return_amount,
  return_cnt
FROM q1
UNION ALL
SELECT
  t_sub_shift,
  w_city,
  total_return_amount,
  return_cnt
FROM q2
ORDER BY total_return_amount DESC
LIMIT 100
