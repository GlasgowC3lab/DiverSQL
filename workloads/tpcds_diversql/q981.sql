WITH catalog_agg AS (
   SELECT
      cr.cr_reason_sk,
      SUM(cr.cr_return_amount) AS total_cr_amount,
      AVG(cr.cr_return_quantity) AS avg_cr_qty,
      COUNT(*) AS cnt_cr
   FROM catalog_returns cr
   JOIN customer_demographics cd
     ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE cr.cr_call_center_sk IN (10, 13, 31)
     AND cr.cr_reversed_charge > 5.00
     AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
     AND cd.cd_dep_count >= 3
   GROUP BY cr.cr_reason_sk
), store_agg AS (
   SELECT
      sr.sr_reason_sk,
      SUM(sr.sr_return_amt) AS sum_sr_amount,
      AVG(sr.sr_return_quantity) AS avg_sr_qty,
      COUNT(*) AS cnt_sr
   FROM store_returns sr
   TABLESAMPLE BERNOULLI (10)
   JOIN customer_demographics cd2
     ON sr.sr_cdemo_sk = cd2.cd_demo_sk
   WHERE sr.sr_store_credit > 10.00
     AND sr.sr_return_ship_cost >= 0.00
     AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2459999
     AND cd2.cd_dep_college_count > 2
   GROUP BY sr.sr_reason_sk
)
SELECT
   COALESCE(ca.cr_reason_sk, sa.sr_reason_sk) AS reason_sk,
   r.r_reason_desc,
   ca.total_cr_amount,
   ca.avg_cr_qty,
   ca.cnt_cr,
   sa.sum_sr_amount,
   sa.avg_sr_qty,
   sa.cnt_sr,
   l.total_store_return_for_reason
FROM catalog_agg ca
FULL OUTER JOIN store_agg sa
   ON ca.cr_reason_sk = sa.sr_reason_sk
LEFT JOIN reason r
   ON COALESCE(ca.cr_reason_sk, sa.sr_reason_sk) = r.r_reason_sk
LEFT JOIN LATERAL (
   SELECT SUM(s3.sr_return_amt) AS total_store_return_for_reason
   FROM store_returns s3
   WHERE s3.sr_reason_sk = COALESCE(ca.cr_reason_sk, sa.sr_reason_sk)
) l ON TRUE
WHERE ca.total_cr_amount IS NOT NULL OR sa.sum_sr_amount IS NOT NULL
ORDER BY ca.total_cr_amount DESC NULLS LAST
LIMIT 100
