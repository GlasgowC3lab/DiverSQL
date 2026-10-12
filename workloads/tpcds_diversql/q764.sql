WITH agg AS (
  SELECT
    w.w_warehouse_id,
    r.r_reason_desc,
    d.d_year,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    CASE WHEN SUM(cr.cr_return_amount) > 1000 THEN 'High' ELSE 'Low' END AS return_category
  FROM catalog_returns cr
  JOIN date_dim d            ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN time_dim t            ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN customer c            ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN warehouse w           ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN reason r              ON cr.cr_reason_sk = r.r_reason_sk
  WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
    AND r.r_reason_desc LIKE '%defect%'
    AND t.t_sub_shift = 'evening'
  GROUP BY CUBE (w.w_warehouse_id, r.r_reason_desc, d.d_year)
)
SELECT
  w_warehouse_id,
  r_reason_desc,
  d_year,
  total_return_amount,
  return_cnt,
  return_category,
  CONCAT(w_warehouse_id, '-', COALESCE(r_reason_desc, 'TOTAL')) AS warehouse_reason_key,
  SUBSTR(r_reason_desc, 1, 10) AS reason_prefix,
  LAG(total_return_amount) OVER (PARTITION BY w_warehouse_id ORDER BY d_year) AS prev_year_return,
  SUM(total_return_amount) OVER (PARTITION BY w_warehouse_id ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_return,
  ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rn
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
