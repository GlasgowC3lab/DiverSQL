WITH intersect_orders AS (
   SELECT cr_order_number
   FROM catalog_returns
   WHERE cr_return_amount > 200
   INTERSECT
   SELECT cr_order_number
   FROM catalog_returns
   WHERE cr_return_quantity >= 3
),
except_orders AS (
   SELECT cr_order_number
   FROM catalog_returns
   WHERE cr_return_tax > 1
   EXCEPT
   SELECT cr_order_number
   FROM catalog_returns
   WHERE cr_fee = 0
),
filtered_returns AS (
   SELECT cr.*
   FROM catalog_returns AS cr
   JOIN intersect_orders AS io ON cr.cr_order_number = io.cr_order_number
   JOIN except_orders   AS eo ON cr.cr_order_number = eo.cr_order_number
   WHERE cr.cr_refunded_cash > 100
     AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
     AND cr.cr_ship_mode_sk IN (
         SELECT sm_ship_mode_sk
         FROM ship_mode
         WHERE sm_code = 'AIR'
     )
     AND cr.cr_refunded_cdemo_sk IN (
         SELECT cd_demo_sk
         FROM customer_demographics
         WHERE cd_gender = 'F'
           AND cd_dep_employed_count >= 2
     )
     AND cr.cr_item_sk IN (
         SELECT i_item_sk
         FROM item
         WHERE i_brand_id = 10
     )
),
joined_data AS (
   SELECT
       fr.cr_order_number,
       sm.sm_ship_mode_id,
       i.i_brand,
       cd.cd_gender,
       fr.cr_return_amount,
       fr.cr_return_quantity,
       fr.cr_return_tax,
       fr.cr_fee
   FROM filtered_returns AS fr
   JOIN item AS i ON fr.cr_item_sk = i.i_item_sk
   JOIN customer_demographics AS cd ON fr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   JOIN ship_mode AS sm ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
)
SELECT
    sm_ship_mode_id,
    i_brand,
    cd_gender,
    COUNT(DISTINCT cr_order_number) AS order_cnt,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cr_return_amount) AS avg_return_amount,
    MIN(cr_return_amount) AS min_return_amount,
    MAX(cr_return_amount) AS max_return_amount,
    SUM(CASE WHEN cr_return_amount > 500 THEN 1 ELSE 0 END) AS high_return_cnt
FROM joined_data
GROUP BY
    sm_ship_mode_id,
    i_brand,
    cd_gender
ORDER BY total_return_amount DESC
LIMIT 100
