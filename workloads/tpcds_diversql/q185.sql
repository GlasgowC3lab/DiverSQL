WITH
  customer_common AS (
    SELECT c_customer_sk FROM (
      SELECT DISTINCT c.c_customer_sk
      FROM store_sales ss
      JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
      WHERE ss.ss_net_paid > 1000
    )
    INTERSECT
    SELECT DISTINCT cs.cs_bill_customer_sk
    FROM catalog_sales cs
    WHERE cs.cs_net_paid > 1000
  ),

  joined_data AS (
    SELECT
      cs.cs_order_number,
      cust_bill.c_customer_sk          AS bill_cust_sk,
      cust_ship.c_customer_sk          AS ship_cust_sk,
      promo.p_promo_id                 AS cat_promo_id,
      sm.sm_ship_mode_id               AS ship_mode_id,
      w.w_warehouse_id                 AS warehouse_id,
      inv.inv_quantity_on_hand,
      ss.ss_ext_discount_amt          AS store_discount,
      lt.line_total,
      kv.key,
      kv.val
    FROM catalog_sales cs
    JOIN customer cust_bill ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk                -- join 1
    JOIN customer cust_ship ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk                -- join 2
    JOIN promotion promo   ON cs.cs_promo_sk = promo.p_promo_sk                                 -- join 3
    JOIN ship_mode sm     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk                           -- join 4
    JOIN warehouse w      ON cs.cs_warehouse_sk = w.w_warehouse_sk                             -- join 5
    JOIN inventory inv    ON inv.inv_warehouse_sk = w.w_warehouse_sk                           -- join 6
    JOIN store_sales ss   ON ss.ss_customer_sk = cust_bill.c_customer_sk                     -- join 7
    JOIN LATERAL (
      SELECT cs.cs_quantity * cs.cs_sales_price AS line_total
    ) lt ON TRUE                                                                          -- join 8 (LATERAL)
    CROSS JOIN UNNEST(
      MAP(
        ARRAY['order_number','warehouse_id'],
        ARRAY[CAST(cs.cs_order_number AS VARCHAR), w.w_warehouse_id]
      )
    ) AS kv(key, val)                                                                     -- join 9 (UNNEST)
  )

SELECT
  jd.warehouse_id,
  jd.cat_promo_id,
  SUM(jd.line_total)            AS total_sales,
  COUNT(DISTINCT jd.cs_order_number) AS order_count,
  SUM(jd.inv_quantity_on_hand) AS total_inventory,
  AVG(jd.store_discount)        AS avg_store_discount
FROM joined_data jd
JOIN customer_common cc ON jd.bill_cust_sk = cc.c_customer_sk
GROUP BY jd.warehouse_id, jd.cat_promo_id
ORDER BY total_sales DESC
LIMIT 100
