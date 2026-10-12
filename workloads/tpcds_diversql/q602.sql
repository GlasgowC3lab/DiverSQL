WITH
  sales_data AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sales_price,
      cs.cs_net_paid,
      cs.cs_warehouse_sk,
      cp.cp_catalog_page_id,
      cd.cd_credit_rating,
      w.w_warehouse_id,
      w.w_state,
      w.w_warehouse_sk
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_end_date_sk > 2451200
      AND cd.cd_credit_rating = 'Good'
      AND w.w_state = 'CA'
      AND cs.cs_sales_price > 100
  ),
  full_joined AS (
    SELECT
      sd.*, 
      inv.inv_quantity_on_hand,
      inv.inv_date_sk
    FROM sales_data sd
    FULL OUTER JOIN inventory inv
      ON sd.cs_warehouse_sk = inv.inv_warehouse_sk
  ),
  union_set AS (
    SELECT
      fj.cs_sold_date_sk,
      fj.w_warehouse_id,
      fj.w_warehouse_sk,
      fj.cs_sales_price,
      fj.inv_quantity_on_hand,
      ROW_NUMBER() OVER (PARTITION BY fj.w_warehouse_id ORDER BY fj.cs_sales_price DESC) AS sales_rank,
      (
        SELECT SUM(inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_warehouse_sk = fj.cs_warehouse_sk
      ) AS total_warehouse_inventory
    FROM full_joined fj
    WHERE fj.inv_quantity_on_hand IS NOT NULL
    UNION
    SELECT
      fj.cs_sold_date_sk,
      fj.w_warehouse_id,
      fj.w_warehouse_sk,
      fj.cs_sales_price,
      fj.inv_quantity_on_hand,
      ROW_NUMBER() OVER (PARTITION BY fj.w_warehouse_id ORDER BY fj.cs_sales_price DESC) AS sales_rank,
      (
        SELECT SUM(inv_quantity_on_hand)
        FROM inventory inv2
        WHERE inv2.inv_warehouse_sk = fj.cs_warehouse_sk
      ) AS total_warehouse_inventory
    FROM full_joined fj
    WHERE fj.inv_quantity_on_hand IS NULL
  ),
  intersect_set AS (
    SELECT w_warehouse_sk FROM sales_data WHERE cd_credit_rating = 'Good'
    INTERSECT
    SELECT inv_warehouse_sk FROM inventory WHERE inv_quantity_on_hand > 500
  )
SELECT
  us.cs_sold_date_sk,
  us.w_warehouse_id,
  us.w_warehouse_sk,
  us.cs_sales_price,
  us.inv_quantity_on_hand,
  us.sales_rank,
  us.total_warehouse_inventory,
  CASE
    WHEN us.sales_rank = 1 THEN 'Top Seller'
    WHEN us.sales_rank <= 5 THEN 'High Seller'
    ELSE 'Other'
  END AS seller_category
FROM union_set us
WHERE us.w_warehouse_sk IN (SELECT w_warehouse_sk FROM intersect_set)
ORDER BY us.cs_sales_price DESC
LIMIT 100
