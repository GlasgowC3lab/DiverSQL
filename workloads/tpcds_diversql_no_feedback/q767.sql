WITH base AS (
   SELECT
       cr.cr_return_amount,
       cr.cr_return_quantity,
       i.i_category,
       i.i_wholesale_cost,
       sm.sm_code,
       sm.sm_type,
       cd.cd_gender,
       hd.hd_income_band_sk,
       cr.cr_item_sk
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE i.i_wholesale_cost BETWEEN 5 AND 50
     AND sm.sm_code IN ('AIR', 'SEA')
     AND cd.cd_gender = 'F'
     AND hd.hd_income_band_sk BETWEEN 2 AND 4
     AND EXISTS (
         SELECT 1
         FROM catalog_returns cr2
         WHERE cr2.cr_item_sk = cr.cr_item_sk
           AND cr2.cr_return_amount > cr.cr_return_amount
     )
)
SELECT
   cd_gender,
   i_category,
   sm_type,
   SUM(cr_return_amount) AS total_return_amount,
   AVG(cr_return_quantity) AS avg_return_quantity,
   COUNT(*) AS return_cnt,
   CASE WHEN SUM(cr_return_amount) > 1000 THEN 'HIGH' ELSE 'LOW' END AS amount_category,
   RANK() OVER (ORDER BY SUM(cr_return_amount) DESC) AS amount_rank
FROM base
GROUP BY CUBE (cd_gender, i_category, sm_type)
HAVING SUM(cr_return_amount) IS NOT NULL
ORDER BY amount_rank
LIMIT 100
