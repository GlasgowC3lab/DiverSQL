WITH base AS (
  SELECT
    i.inv_item_sk,
    i.inv_quantity_on_hand,
    i.inv_date_sk,
    w.w_warehouse_id,
    w.w_state,
    d.d_year,
    d.d_moy,
    p.p_promo_id,
    p.p_discount_active,
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_education_status
  FROM inventory i
  TABLESAMPLE BERNOULLI (10)
  JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
  JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
  LEFT JOIN customer c ON c.c_first_shipto_date_sk = d.d_date_sk
  LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  WHERE i.inv_quantity_on_hand > 100
    AND d.d_moy IN (5, 9)
    AND d.d_year = 2022
    AND w.w_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND cd.cd_gender = 'M'
),
agg1 AS (
  SELECT
    i.w_warehouse_id,
    i.d_year,
    SUM(i.inv_quantity_on_hand) AS total_qty,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items
  FROM base i
  GROUP BY i.w_warehouse_id, i.d_year
  HAVING COUNT(DISTINCT i.inv_item_sk) > 5
),
agg2 AS (
  SELECT
    w_warehouse_id,
    d_year,
    total_qty,
    distinct_items,
    ROW_NUMBER() OVER (ORDER BY total_qty DESC) AS rn
  FROM agg1
)
SELECT *
FROM (
  SELECT w_warehouse_id, d_year, total_qty, distinct_items, rn
  FROM agg2
  WHERE total_qty > (SELECT AVG(total_qty) FROM agg1)
  UNION DISTINCT
  SELECT w_warehouse_id, d_year, total_qty, distinct_items, rn
  FROM agg2
  WHERE total_qty <= (SELECT AVG(total_qty) FROM agg1)
) final_result
WHERE w_warehouse_id NOT IN (
  SELECT w_warehouse_id FROM warehouse WHERE w_country = 'Canada'
)
ORDER BY total_qty DESC
LIMIT 100
