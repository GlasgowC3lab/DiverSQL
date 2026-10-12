WITH base AS (
   SELECT
       w.w_warehouse_id,
       w.w_city,
       d_ret.d_year,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(cr.cr_return_quantity) AS total_return_quantity,
       AVG(cr.cr_return_amount) AS avg_return_amount,
       SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand
   FROM catalog_returns cr
   JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
   LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   RIGHT OUTER JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN inventory i ON i.inv_date_sk = d_ret.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
   LEFT JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
   WHERE d_ret.d_year = 2002
     AND cc.cc_state = 'CA'
     AND cp.cp_type = 'Electronics'
     AND sm.sm_type = 'AIR'
     AND r.r_reason_desc = 'Damaged'
     AND w.w_state = 'TX'
     AND cd_ref.cd_education_status = 'College'
   GROUP BY w.w_warehouse_id, w.w_city, d_ret.d_year
),
filtered AS (
   SELECT *
   FROM base
   WHERE total_return_amount > 10000
)
SELECT
   f.d_year,
   COUNT(DISTINCT f.w_warehouse_id) AS warehouse_count,
   AVG(f.total_return_amount) AS avg_return_per_warehouse,
   SUM(f.total_inventory_on_hand) AS total_inventory_across_warehouses
FROM filtered f
GROUP BY f.d_year
ORDER BY avg_return_per_warehouse DESC
LIMIT 100
