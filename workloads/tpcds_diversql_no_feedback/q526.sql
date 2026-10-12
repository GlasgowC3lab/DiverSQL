WITH returns AS (
   SELECT
       i.i_item_id AS item_id,
       i.i_product_name AS product_name,
       'return' AS metric_type,
       SUM(sr.sr_return_amt) AS metric_value,
       CASE WHEN SUM(sr.sr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS amount_category,
       d.d_date AS metric_date,
       t.t_meal_time AS meal_time
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   WHERE d.d_year = 2001
   GROUP BY i.i_item_id, i.i_product_name, d.d_date, t.t_meal_time
),
promotions AS (
   SELECT
       i.i_item_id AS item_id,
       i.i_product_name AS product_name,
       'inventory' AS metric_type,
       SUM(inv.inv_quantity_on_hand) AS metric_value,
       CASE WHEN SUM(inv.inv_quantity_on_hand) > 500 THEN 'High' ELSE 'Low' END AS amount_category,
       d_inv.d_date AS metric_date,
       CAST(NULL AS varchar) AS meal_time
   FROM promotion p
   JOIN item i ON p.p_item_sk = i.i_item_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
   JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
   WHERE inv.inv_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
     AND d_inv.d_year = 2001
   GROUP BY i.i_item_id, i.i_product_name, d_inv.d_date
)
SELECT * FROM returns
UNION ALL
SELECT * FROM promotions
ORDER BY metric_value DESC, metric_date ASC
LIMIT 100
