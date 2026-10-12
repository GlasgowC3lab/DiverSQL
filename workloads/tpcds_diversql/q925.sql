WITH sales_agg AS (
   SELECT
       cs.cs_order_number,
       cs.cs_item_sk,
       cs.cs_call_center_sk,
       cs.cs_warehouse_sk,
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_catalog_page_sk,
       cs.cs_promo_sk,
       SUM(cs.cs_ext_sales_price) AS total_sales,
       SUM(cs.cs_net_profit) AS total_profit,
       COUNT(*) AS sales_cnt,
       CASE WHEN SUM(cs.cs_ext_sales_price) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
   FROM catalog_sales cs
   WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000          -- surrogate date range filter
     AND cs.cs_quantity > 5                                      -- quantity filter
     AND cs.cs_coupon_amt > 0                                    -- coupon amount filter
     AND cs.cs_list_price >= 20                                 -- list price filter
     AND cs.cs_ext_discount_amt <= 200                          -- discount filter
     AND cs.cs_wholesale_cost > 2                               -- wholesale cost filter
   GROUP BY GROUPING SETS (
       (cs.cs_item_sk, cs.cs_call_center_sk, cs.cs_warehouse_sk, cs.cs_sold_date_sk, cs.cs_sold_time_sk, cs.cs_order_number, cs.cs_catalog_page_sk, cs.cs_promo_sk),
       (cs.cs_call_center_sk, cs.cs_warehouse_sk, cs.cs_sold_date_sk, cs.cs_sold_time_sk, cs.cs_catalog_page_sk, cs.cs_promo_sk),
       (cs.cs_call_center_sk, cs.cs_warehouse_sk, cs.cs_catalog_page_sk, cs.cs_promo_sk)
   )
),
returns_set AS (
   SELECT cr.cr_order_number
   FROM catalog_returns cr
   WHERE cr.cr_return_quantity > 0
),
non_return_sales AS (
   SELECT sa.*
   FROM sales_agg sa
   EXCEPT
   SELECT sa.*
   FROM sales_agg sa
   JOIN returns_set rs ON sa.cs_order_number = rs.cr_order_number
)
SELECT
   nr.cs_order_number,
   i.i_product_name,
   cc.cc_name,
   w.w_warehouse_name,
   td.t_hour,
   cp.cp_description,
   p.p_promo_name,
   nr.total_sales,
   nr.total_profit,
   nr.sales_category,
   (SELECT SUM(inv.inv_quantity_on_hand)
      FROM inventory inv
      WHERE inv.inv_item_sk = nr.cs_item_sk
        AND inv.inv_warehouse_sk = nr.cs_warehouse_sk) AS inventory_on_hand,
   CASE
       WHEN nr.total_profit / NULLIF(nr.total_sales, 0) > 0.2 THEN 'MARGIN_HIGH'
       ELSE 'MARGIN_LOW'
   END AS profit_margin_category,
   r.r_reason_desc
FROM non_return_sales nr
-- left‑deep join chain using only allowed join keys
JOIN time_dim td          ON nr.cs_sold_time_sk = td.t_time_sk
JOIN call_center cc      ON nr.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp      ON nr.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w          ON nr.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i               ON nr.cs_item_sk = i.i_item_sk
JOIN promotion p          ON nr.cs_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr ON nr.cs_order_number = cr.cr_order_number
LEFT JOIN reason r          ON cr.cr_reason_sk = r.r_reason_sk
WHERE cc.cc_country = 'United States'          -- filter 1
  AND w.w_state = 'CA'                         -- filter 2
  AND i.i_category = 'Sports'                  -- filter 3
  AND i.i_brand_id IN (1, 2, 3)                -- filter 4
  AND td.t_hour BETWEEN 8 AND 20               -- filter 5
  AND p.p_discount_active = 'Y'                -- filter 6
ORDER BY nr.total_sales DESC
LIMIT 100
