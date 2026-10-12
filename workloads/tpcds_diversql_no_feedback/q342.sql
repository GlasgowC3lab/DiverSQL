WITH
  cs_agg AS (
    SELECT cs_item_sk,
           cs_warehouse_sk,
           SUM(cs_net_paid)        AS total_sales,
           COUNT(*)                AS sales_orders
    FROM catalog_sales
    WHERE cs_quantity > 0
      AND cs_sales_price > 10
      AND cs_ext_discount_amt >= 0
      AND cs_ext_tax >= 0
    GROUP BY cs_item_sk, cs_warehouse_sk
  ),
  sr_agg AS (
    SELECT sr_item_sk,
           SUM(sr_net_loss) AS total_loss,
           COUNT(*)         AS return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_amt > 0
      AND sr_fee >= 0
      AND sr_return_ship_cost >= 0
    GROUP BY sr_item_sk
  ),
  common_items AS (
    SELECT cs_item_sk AS i_item_sk FROM cs_agg
    INTERSECT
    SELECT sr_item_sk FROM sr_agg
  )
SELECT
  i.i_brand,
  i.i_category,
  SUM(cs_agg.total_sales)          AS total_sales,
  SUM(sr_agg.total_loss)           AS total_loss,
  COUNT(DISTINCT cs_raw.cs_order_number) AS order_cnt,
  COUNT(DISTINCT ws.ws_order_number)      AS web_order_cnt
FROM common_items ci
JOIN item i ON i.i_item_sk = ci.i_item_sk
JOIN cs_agg ON cs_agg.cs_item_sk = i.i_item_sk
JOIN catalog_sales cs_raw
     ON cs_raw.cs_item_sk = i.i_item_sk
    AND cs_raw.cs_warehouse_sk = cs_agg.cs_warehouse_sk
JOIN catalog_returns cr
     ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_order_number = cs_raw.cs_order_number
JOIN call_center cc
     ON cc.cc_call_center_sk = cs_raw.cs_call_center_sk
JOIN catalog_page cp
     ON cp.cp_catalog_page_sk = cs_raw.cs_catalog_page_sk
JOIN ship_mode sm
     ON sm.sm_ship_mode_sk = cs_raw.cs_ship_mode_sk
JOIN warehouse w
     ON w.w_warehouse_sk = cs_raw.cs_warehouse_sk
JOIN promotion p
     ON p.p_promo_sk = cs_raw.cs_promo_sk
JOIN inventory inv
     ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN sr_agg ON sr_agg.sr_item_sk = i.i_item_sk
JOIN store_returns sr
     ON sr.sr_item_sk = i.i_item_sk
JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_promo_sk = p.p_promo_sk
WHERE i.i_current_price BETWEEN 50 AND 500
  AND i.i_units = 'Box'
  AND sm.sm_type = 'OVERNIGHT'
  AND cc.cc_country = 'United States'
  AND cc.cc_rec_start_date > DATE '2000-01-01'
  AND EXISTS (
        SELECT 1 FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_discount_active = 'Y'
      )
GROUP BY GROUPING SETS (
  (i.i_brand, i.i_category),
  (i.i_brand),
  ()
)
ORDER BY total_sales DESC
LIMIT 100
