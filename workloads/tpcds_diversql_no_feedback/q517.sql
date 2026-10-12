WITH agg_cte AS (
   SELECT
       w.w_warehouse_id,
       w.w_warehouse_name,
       w.w_county,
       i.inv_item_sk,
       SUM(i.inv_quantity_on_hand) AS total_qty,
       COUNT(DISTINCT i.inv_date_sk) AS distinct_dates
   FROM inventory i
   JOIN warehouse w
     ON i.inv_warehouse_sk = w.w_warehouse_sk
   WHERE i.inv_item_sk IN (101410, 101437, 101432, 101428, 101414)
     AND i.inv_quantity_on_hand > 0
     AND w.w_warehouse_sq_ft BETWEEN 600000 AND 950000
     AND w.w_county IN ('Wadena County', 'Fairfield County', 'Ziebach County', 'Franklin Parish', 'Oglethorpe County')
     AND w.w_suite_number LIKE 'Suite %'
   GROUP BY CUBE (w.w_warehouse_id, w.w_warehouse_name, w.w_county, i.inv_item_sk)
),
agg2 AS (
   SELECT
       w_warehouse_id,
       w_warehouse_name,
       w_county,
       AVG(total_qty) AS avg_total_qty,
       SUM(total_qty) AS sum_total_qty,
       COUNT(*) AS cnt_rows
   FROM agg_cte
   WHERE w_warehouse_id IS NOT NULL
   GROUP BY w_warehouse_id, w_warehouse_name, w_county
)
SELECT
   a2.w_warehouse_id,
   a2.w_warehouse_name,
   a2.w_county,
   a2.avg_total_qty,
   a2.sum_total_qty,
   a2.cnt_rows,
   lat.avg_qty_per_warehouse,
   ROW_NUMBER() OVER (ORDER BY a2.avg_total_qty DESC) AS rn
FROM agg2 a2
CROSS JOIN LATERAL (
   SELECT a2.sum_total_qty / NULLIF(a2.cnt_rows, 0) AS avg_qty_per_warehouse
) AS lat
WHERE a2.sum_total_qty >= 500
  AND a2.avg_total_qty > 0
  AND a2.cnt_rows >= 2
  AND a2.w_county LIKE '%County%'
  AND a2.w_warehouse_name <> ''
ORDER BY a2.avg_total_qty DESC
LIMIT 100
