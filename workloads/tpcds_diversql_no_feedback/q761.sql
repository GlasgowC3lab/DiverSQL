WITH
  moderate_returns AS (
    SELECT DISTINCT cr_warehouse_sk, cr_item_sk
    FROM catalog_returns
    WHERE cr_return_amount > 20
  ),
  high_returns AS (
    SELECT DISTINCT cr_warehouse_sk, cr_item_sk
    FROM catalog_returns
    WHERE cr_return_amount > 100
  ),
  filtered_keys AS (
    SELECT cr_warehouse_sk, cr_item_sk
    FROM moderate_returns
    EXCEPT
    SELECT cr_warehouse_sk, cr_item_sk
    FROM high_returns
  )
SELECT
  w.w_warehouse_name,
  i.i_brand,
  cd.cd_gender,
  COUNT(DISTINCT cr.cr_order_number) AS orders_returned,
  SUM(cr.cr_return_amount) AS total_return_amount,
  AVG(cr.cr_return_amount) AS avg_return_amount,
  MIN(cr.cr_return_amount) AS min_return_amount,
  MAX(cr.cr_return_amount) AS max_return_amount,
  SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
FROM catalog_returns cr
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN filtered_keys fk
  ON fk.cr_warehouse_sk = cr.cr_warehouse_sk
 AND fk.cr_item_sk = cr.cr_item_sk
WHERE i.i_current_price BETWEEN 5 AND 8
  AND i.i_container = 'Unknown'
  AND i.i_formulation = '42214rosy28066558020'
  AND inv.inv_quantity_on_hand > 10
  AND inv.inv_date_sk BETWEEN 2450927 AND 2451088
  AND cr.cr_return_amount > 15
  AND cr.cr_returned_date_sk BETWEEN 2451000 AND 2451050
  AND cd.cd_gender = 'F'
  AND cd.cd_education_status = 'College'
GROUP BY
  w.w_warehouse_name,
  i.i_brand,
  cd.cd_gender
ORDER BY total_return_amount DESC
