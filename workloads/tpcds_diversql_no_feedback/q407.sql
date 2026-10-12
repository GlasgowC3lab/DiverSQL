WITH base AS (
  SELECT
    cr.cr_returned_date_sk,
    cr.cr_returned_time_sk,
    cr.cr_item_sk,
    cr.cr_ship_mode_sk,
    cr.cr_reason_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_fee,
    cr.cr_return_tax,
    cr.cr_return_amt_inc_tax,
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    t.t_shift,
    i.i_category,
    i.i_brand,
    sm.sm_type,
    r.r_reason_desc,
    inv.inv_quantity_on_hand
  FROM catalog_returns cr
  LEFT JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
  LEFT JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  LEFT JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  FULL OUTER JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND d.d_month_seq BETWEEN 1200 AND 1215
    AND t.t_hour BETWEEN 8 AND 17
    AND t.t_shift = 'first'
    AND i.i_category = 'Sports'
    AND sm.sm_type = 'AIR'
    AND cr.cr_return_quantity > 0
),
exploded AS (
  SELECT
    b.*, 
    u.amount_value,
    CASE u.idx
      WHEN 1 THEN 'return_amount'
      WHEN 2 THEN 'fee'
      WHEN 3 THEN 'tax'
      ELSE 'other'
    END AS amount_type
  FROM base b
  CROSS JOIN UNNEST(ARRAY[b.cr_return_amount, b.cr_fee, b.cr_return_tax]) WITH ORDINALITY AS u(amount_value, idx)
),
agg1 AS (
  SELECT
    e.i_category,
    e.i_brand,
    e.d_year,
    e.d_month_seq,
    e.t_hour,
    SUM(e.amount_value) AS total_amount,
    COUNT(*) AS cnt,
    AVG(e.amount_value) AS avg_amount
  FROM exploded e
  GROUP BY e.i_category, e.i_brand, e.d_year, e.d_month_seq, e.t_hour
)
SELECT
  a.i_category,
  a.i_brand,
  AVG(a.total_amount) AS avg_monthly_amount,
  SUM(a.cnt) AS total_returns
FROM agg1 a
WHERE a.total_amount > 1000
  AND a.avg_amount > 50
  AND a.cnt >= 5
  AND a.d_year = 2001
  AND a.t_hour BETWEEN 9 AND 16
  AND a.i_category = 'Sports'
GROUP BY a.i_category, a.i_brand
HAVING AVG(a.total_amount) > 2000
ORDER BY avg_monthly_amount DESC
LIMIT 100
