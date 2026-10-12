WITH refunded_returns AS (
   SELECT
       cr.cr_returned_date_sk,
       cp.cp_catalog_page_number,
       hd.hd_buy_potential,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       ROW_NUMBER() OVER (ORDER BY cr.cr_returned_date_sk) AS rn,
       SUM(cr.cr_return_amount) OVER (
           PARTITION BY cp.cp_catalog_page_number
           ORDER BY cr.cr_returned_date_sk
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_return_amount
   FROM catalog_returns AS cr
   JOIN catalog_page AS cp
       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN household_demographics AS hd
       ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE cr.cr_refunded_hdemo_sk IN (
       SELECT hd_demo_sk FROM household_demographics WHERE hd_dep_count > 5
   )
     AND cp.cp_end_date_sk BETWEEN 2450900 AND 2451100
),
returning_returns AS (
   SELECT
       cr.cr_returned_date_sk,
       cp.cp_catalog_page_number,
       hd.hd_buy_potential,
       cr.cr_return_amount,
       cr.cr_return_quantity,
       ROW_NUMBER() OVER (ORDER BY cr.cr_returned_date_sk) AS rn,
       SUM(cr.cr_return_amount) OVER (
           PARTITION BY cp.cp_catalog_page_number
           ORDER BY cr.cr_returned_date_sk
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_return_amount
   FROM catalog_returns AS cr
   JOIN catalog_page AS cp
       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN household_demographics AS hd
       ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
   WHERE hd.hd_buy_potential LIKE '%1000%'
     AND cp.cp_catalog_page_number IN (
         SELECT cp_catalog_page_number FROM catalog_page WHERE cp_department = 'HOME'
     )
)
SELECT
   cr_returned_date_sk,
   cp_catalog_page_number,
   hd_buy_potential,
   cr_return_amount,
   cr_return_quantity,
   rn,
   running_return_amount
FROM (
   SELECT * FROM refunded_returns
   UNION ALL
   SELECT * FROM returning_returns
) AS combined
ORDER BY rn
LIMIT 100
