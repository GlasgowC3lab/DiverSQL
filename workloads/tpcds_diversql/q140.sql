WITH
  items_not_returned AS (
    SELECT cs_item_sk AS item_sk
    FROM catalog_sales
    EXCEPT
    SELECT sr_item_sk
    FROM store_returns
  ),
  items_in_inventory_and_return AS (
    SELECT inv_item_sk AS item_sk
    FROM inventory
    INTERSECT
    SELECT cr_item_sk
    FROM catalog_returns
  ),
  joined_data AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_ext_sales_price,
      cs.cs_quantity,
      cs.cs_net_profit,
      cp.cp_catalog_page_number,
      sm.sm_carrier,
      i1.i_category,
      i1.i_item_sk,
      cd_bill.cd_gender AS bill_gender,
      cd_ship.cd_gender AS ship_gender,
      cr.cr_return_quantity,
      cr.cr_return_amount,
      cd_refunded.cd_gender AS refunded_gender,
      cd_returning.cd_gender AS returning_gender,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i1
      ON cs.cs_item_sk = i1.i_item_sk
    JOIN customer_demographics cd_bill
      ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship
      ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN item i2
      ON cr.cr_item_sk = i2.i_item_sk
    LEFT JOIN customer_demographics cd_refunded
      ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    LEFT JOIN customer_demographics cd_returning
      ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    LEFT JOIN catalog_page cp2
      ON cr.cr_catalog_page_sk = cp2.cp_catalog_page_sk
    LEFT JOIN ship_mode sm2
      ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = cs.cs_item_sk
    LEFT JOIN item i3
      ON sr.sr_item_sk = i3.i_item_sk
    LEFT JOIN inventory inv
      ON inv.inv_item_sk = cs.cs_item_sk
    LEFT JOIN items_not_returned innr
      ON cs.cs_item_sk = innr.item_sk
    LEFT JOIN items_in_inventory_and_return iir
      ON cs.cs_item_sk = iir.item_sk
    WHERE cs.cs_sold_date_sk = 2451545
  )
SELECT
  i_category,
  sm_carrier,
  cp_catalog_page_number,
  bill_gender,
  ship_gender,
  COUNT(DISTINCT cs_order_number) AS orders_count,
  SUM(cs_ext_sales_price) AS total_sales_price,
  SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_return_amount,
  SUM(COALESCE(sr_return_amt, 0)) AS total_store_return_amount,
  AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
  SUM(CASE
        WHEN cs_ext_sales_price > (
          SELECT MAX(cs_ext_sales_price)
          FROM catalog_sales
          WHERE cs_sold_date_sk = 2451545
        ) THEN 1 ELSE 0 END) AS above_max_price_rows
FROM joined_data
GROUP BY
  i_category,
  sm_carrier,
  cp_catalog_page_number,
  bill_gender,
  ship_gender
ORDER BY total_sales_price DESC
LIMIT 100
