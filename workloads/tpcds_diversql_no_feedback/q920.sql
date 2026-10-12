WITH catalog_agg AS (
   SELECT
      cs.cs_item_sk,
      i.i_item_id,
      cp.cp_department,
      SUM(cs.cs_quantity) AS total_quantity_sold,
      SUM(cs.cs_net_paid) AS total_net_paid,
      AVG(cs.cs_sales_price) AS avg_sales_price,
      SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
      ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY SUM(cs.cs_net_paid) DESC) AS dept_sales_rank
   FROM catalog_sales cs
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN item i
     ON cs.cs_item_sk = i.i_item_sk
   LEFT JOIN promotion p
     ON cs.cs_promo_sk = p.p_promo_sk
   LEFT JOIN catalog_returns cr
     ON cs.cs_item_sk = cr.cr_item_sk
    AND cs.cs_order_number = cr.cr_order_number
   LEFT JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN inventory inv
     ON i.i_item_sk = inv.inv_item_sk
   GROUP BY cs.cs_item_sk, i.i_item_id, cp.cp_department
),

store_agg AS (
   SELECT
      ss.ss_item_sk,
      i2.i_item_id,
      SUM(ss.ss_quantity) AS store_quantity_sold,
      SUM(ss.ss_net_paid) AS store_net_paid,
      ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS item_store_rank
   FROM store_sales ss
   JOIN item i2
     ON ss.ss_item_sk = i2.i_item_sk
   LEFT JOIN promotion p2
     ON ss.ss_promo_sk = p2.p_promo_sk
   GROUP BY ss.ss_item_sk, i2.i_item_id
),

common_items AS (
   SELECT cs_item_sk FROM catalog_agg
   INTERSECT
   SELECT ss_item_sk FROM store_agg
)

SELECT
   ca.i_item_id,
   ca.cp_department,
   ca.total_quantity_sold,
   ca.total_net_paid,
   ca.avg_sales_price,
   ca.total_inventory_on_hand,
   sa.store_quantity_sold,
   sa.store_net_paid,
   ca.dept_sales_rank,
   sa.item_store_rank,
   CASE
       WHEN ca.total_net_paid > sa.store_net_paid THEN 'Catalog higher'
       WHEN ca.total_net_paid < sa.store_net_paid THEN 'Store higher'
       ELSE 'Equal'
   END AS revenue_comparison
FROM catalog_agg ca
FULL OUTER JOIN store_agg sa
   ON ca.cs_item_sk = sa.ss_item_sk
WHERE ca.cp_department = 'Sports'
  AND ca.total_quantity_sold > 100
  AND (sa.store_quantity_sold IS NULL OR sa.store_quantity_sold > 50)
  AND ca.cs_item_sk IN (SELECT cs_item_sk FROM common_items)
ORDER BY ca.total_net_paid DESC
LIMIT 100
