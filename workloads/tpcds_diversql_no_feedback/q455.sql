/* goal: Identify high‑value catalog returns by call center, reason and demographic segment, using deep joins, a full outer join, a correlated EXISTS filter, an INTERSECT‑derived set, and pre‑aggregation. */
WITH
  /* Aggregate catalog returns to the level needed for the final analysis */
  agg_returns AS (
    SELECT
      cr_call_center_sk,
      cr_returned_date_sk,
      cr_reason_sk,
      cr_refunded_customer_sk,
      cr_returning_customer_sk,
      SUM(cr_return_amount)  AS total_return_amount,
      SUM(cr_return_quantity) AS total_return_quantity
    FROM catalog_returns
    GROUP BY
      cr_call_center_sk,
      cr_returned_date_sk,
      cr_reason_sk,
      cr_refunded_customer_sk,
      cr_returning_customer_sk
  ),
  /* Call‑center IDs that satisfy two independent conditions – used later in a full outer join */
  intersect_cc AS (
    SELECT cc_call_center_id
    FROM call_center
    WHERE cc_tax_percentage > 0.02
    INTERSECT
    SELECT cc_call_center_id
    FROM call_center
    WHERE cc_division = 3
  ),
  /* Restrict reasons to a meaningful subset */
  filtered_reason AS (
    SELECT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE '%damaged%'
  )
SELECT
  cc.cc_call_center_id,
  cc.cc_name,
  d_ret.d_year AS return_year,
  d_full.d_month_seq AS open_month_seq,
  ib_refunded.ib_lower_bound,
  ib_refunded.ib_upper_bound,
  fr.r_reason_desc,
  SUM(ar.total_return_amount)  AS sum_return_amount,
  SUM(ar.total_return_quantity) AS sum_return_quantity,
  COUNT(DISTINCT c_refunded.c_customer_sk)  AS distinct_refunded_customers,
  COUNT(DISTINCT c_returning.c_customer_sk) AS distinct_returning_customers
FROM intersect_cc icc
FULL OUTER JOIN call_center cc
  ON icc.cc_call_center_id = cc.cc_call_center_id
INNER JOIN agg_returns ar
  ON ar.cr_call_center_sk = cc.cc_call_center_sk
INNER JOIN date_dim d_ret
  ON ar.cr_returned_date_sk = d_ret.d_date_sk
FULL OUTER JOIN date_dim d_full
  ON cc.cc_open_date_sk = d_full.d_date_sk
INNER JOIN filtered_reason fr
  ON ar.cr_reason_sk = fr.r_reason_sk
INNER JOIN customer c_refunded
  ON ar.cr_refunded_customer_sk = c_refunded.c_customer_sk
INNER JOIN household_demographics hd_refunded
  ON c_refunded.c_current_hdemo_sk = hd_refunded.hd_demo_sk
INNER JOIN income_band ib_refunded
  ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
INNER JOIN customer c_returning
  ON ar.cr_returning_customer_sk = c_returning.c_customer_sk
INNER JOIN household_demographics hd_returning
  ON c_returning.c_current_hdemo_sk = hd_returning.hd_demo_sk
INNER JOIN income_band ib_returning
  ON hd_returning.hd_income_band_sk = ib_returning.ib_income_band_sk
WHERE EXISTS (
  SELECT 1
  FROM catalog_returns cr
  WHERE cr.cr_call_center_sk = cc.cc_call_center_sk
    AND cr.cr_return_amount > 1000
)
GROUP BY
  cc.cc_call_center_id,
  cc.cc_name,
  d_ret.d_year,
  d_full.d_month_seq,
  ib_refunded.ib_lower_bound,
  ib_refunded.ib_upper_bound,
  fr.r_reason_desc
ORDER BY
  sum_return_amount DESC,
  cc.cc_call_center_id
LIMIT 100
