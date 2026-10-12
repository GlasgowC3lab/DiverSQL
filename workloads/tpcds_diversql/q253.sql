WITH
  cc_filtered AS (
    SELECT
      cc_call_center_sk,
      cc_name,
      cc_city,
      cc_state,
      cc_zip,
      CONCAT(cc_city, ', ', cc_state) AS location,
      SUBSTR(cc_zip, 1, 5) AS zip_prefix
    FROM call_center
    WHERE REGEXP_LIKE(cc_name, 'Center')
      AND cc_city LIKE 'A%'
  ),
  promo_filtered AS (
    SELECT
      p_promo_sk,
      p_promo_name,
      REGEXP_EXTRACT(p_purpose, '(\\w+)', 1) AS purpose_word
    FROM promotion
    WHERE REGEXP_LIKE(p_purpose, 'Discount')
  ),
  loss_by_cc AS (
    SELECT
      ccf.cc_call_center_sk,
      ccf.cc_name,
      ccf.location,
      ccf.zip_prefix,
      d.d_year,
      SUM(cr.cr_net_loss) AS total_net_loss,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN cc_filtered ccf ON cs.cs_call_center_sk = ccf.cc_call_center_sk
    JOIN promo_filtered pf ON cs.cs_promo_sk = pf.p_promo_sk
    GROUP BY
      ccf.cc_call_center_sk,
      ccf.cc_name,
      ccf.location,
      ccf.zip_prefix,
      d.d_year
  ),
  positive_keys AS (
    SELECT cc_call_center_sk, d_year
    FROM loss_by_cc
    WHERE total_net_loss > 0
  ),
  zero_keys AS (
    SELECT cc_call_center_sk, d_year
    FROM loss_by_cc
    WHERE total_net_loss = 0
  ),
  net_keys AS (
    SELECT cc_call_center_sk, d_year
    FROM positive_keys
    EXCEPT
    SELECT cc_call_center_sk, d_year
    FROM zero_keys
  ),
  final_ranked AS (
    SELECT
      lb.cc_call_center_sk,
      lb.cc_name,
      lb.location,
      lb.zip_prefix,
      lb.d_year,
      lb.total_net_loss,
      lb.return_cnt,
      ROW_NUMBER() OVER (PARTITION BY lb.d_year ORDER BY lb.total_net_loss DESC) AS rn
    FROM loss_by_cc lb
    JOIN net_keys nk
      ON lb.cc_call_center_sk = nk.cc_call_center_sk
     AND lb.d_year = nk.d_year
  )
SELECT
  cc_call_center_sk,
  cc_name,
  location,
  zip_prefix,
  d_year,
  total_net_loss,
  return_cnt,
  rn
FROM final_ranked
ORDER BY d_year DESC, rn
LIMIT 100
