WITH agg_inv AS (
   SELECT
       inv.inv_item_sk AS i_item_sk,
       inv.inv_warehouse_sk AS w_warehouse_sk,
       d.d_year,
       SUM(inv.inv_quantity_on_hand) AS total_qty
   FROM inventory inv
   JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_current_year = 'Y'
     AND d.d_moy = 12
     AND d.d_dow IN (1, 3, 5)
     AND w.w_state = 'CA'
     AND i.i_category = 'Women'
   GROUP BY inv.inv_item_sk, inv.inv_warehouse_sk, d.d_year
),
promo_stats AS (
   SELECT
       p.p_item_sk,
       MAX(p.p_cost) AS max_cost,
       COUNT(*) AS promo_cnt
   FROM promotion p
   WHERE p.p_start_date_sk BETWEEN 2450800 AND 2451100
   GROUP BY p.p_item_sk
),
items_without_promo AS (
   SELECT i_item_sk FROM item
   EXCEPT
   SELECT p_item_sk FROM promotion
),
scalar_avg_women_promo AS (
   SELECT AVG(p.p_cost) AS avg_cost
   FROM promotion p
   JOIN item i ON p.p_item_sk = i.i_item_sk
   WHERE i.i_category = 'Women'
)
SELECT
   sub.i_item_sk,
   sub.i_product_name,
   sub.w_warehouse_sk,
   sub.w_warehouse_name,
   sub.d_year,
   sub.total_qty,
   sub.max_cost,
   CASE
       WHEN sub.max_cost > (SELECT avg_cost FROM scalar_avg_women_promo) THEN 'Above Avg'
       ELSE 'Below Avg'
   END AS cost_flag,
   sub.rn
FROM (
   SELECT
       agg.i_item_sk,
       i.i_product_name,
       agg.w_warehouse_sk,
       w.w_warehouse_name,
       agg.d_year,
       agg.total_qty,
       ps.max_cost,
       i.i_category,
       ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY agg.total_qty DESC) AS rn
   FROM agg_inv agg
   JOIN item i ON agg.i_item_sk = i.i_item_sk
   JOIN warehouse w ON agg.w_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN promo_stats ps ON i.i_item_sk = ps.p_item_sk
   WHERE i.i_item_sk IN (SELECT i_item_sk FROM items_without_promo)
     AND EXISTS (
         SELECT 1 FROM promotion p_check
         WHERE p_check.p_item_sk = i.i_item_sk
           AND p_check.p_cost > 1000
     )
) sub
WHERE sub.rn <= 5
ORDER BY sub.i_category, sub.rn
LIMIT 100
