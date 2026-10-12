WITH
  a AS (
    SELECT w.w_warehouse_id,
           SUM(cr.cr_return_amount) AS total_return_a
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE t.t_hour = 9
    GROUP BY w.w_warehouse_id
  ),
  b AS (
    SELECT w.w_warehouse_id,
           SUM(cr.cr_return_amount) AS total_return_b
    FROM catalog_returns cr
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
    GROUP BY w.w_warehouse_id
  ),
  intersect_ids AS (
    SELECT a.w_warehouse_id
    FROM a
    INTERSECT
    SELECT b.w_warehouse_id
    FROM b
  ),
  c AS (
    SELECT w.w_warehouse_id
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE inv.inv_quantity_on_hand > 0
  ),
  union_ids AS (
    SELECT w_warehouse_id FROM intersect_ids
    UNION
    SELECT w_warehouse_id FROM c
  ),
  agg_inventory AS (
    SELECT w.w_warehouse_id,
           AVG(inv.inv_quantity_on_hand) AS avg_quantity
    FROM inventory inv
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_id
  ),
  full_join AS (
    SELECT
      CASE
        WHEN u.w_warehouse_id IS NOT NULL THEN u.w_warehouse_id
        ELSE ai.w_warehouse_id
      END AS w_warehouse_id,
      ai.avg_quantity
    FROM union_ids u
    FULL OUTER JOIN agg_inventory ai ON u.w_warehouse_id = ai.w_warehouse_id
  ),
  small_time AS (
    SELECT t.t_time_id,
           t.t_hour
    FROM time_dim t
    WHERE t.t_hour BETWEEN 9 AND 10
  )
SELECT
  fj.w_warehouse_id,
  fj.avg_quantity,
  st.t_time_id,
  st.t_hour
FROM full_join fj
CROSS JOIN small_time st
ORDER BY fj.w_warehouse_id, st.t_time_id
