WITH filtered_a AS (
   SELECT DISTINCT cr.cr_call_center_sk
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 2002
     AND regexp_like(i.i_color, '^[sS].*')
     AND w.w_city LIKE 'S%'
),
filtered_b AS (
   SELECT DISTINCT cr.cr_call_center_sk
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year = 2002
     AND regexp_like(i.i_color, '^[tT].*')
     AND w.w_city LIKE 'T%'
),
selected_cc AS (
   SELECT cr_call_center_sk
   FROM filtered_a
   EXCEPT
   SELECT cr_call_center_sk FROM filtered_b
)
SELECT
   cc.cc_call_center_id,
   cc.cc_name,
   cc.cc_state,
   SUM(cr.cr_return_amount) AS total_return_amount,
   CONCAT(i.i_color, '-', substr(w.w_city, 1, 3)) AS color_city_code,
   regexp_extract(i.i_item_id, '(\\d+)') AS numeric_item_id
FROM selected_cc sc
JOIN call_center cc ON sc.cr_call_center_sk = cc.cc_call_center_sk
JOIN catalog_returns cr ON cc.cc_call_center_sk = cr.cr_call_center_sk
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2002
GROUP BY
   cc.cc_call_center_id,
   cc.cc_name,
   cc.cc_state,
   CONCAT(i.i_color, '-', substr(w.w_city, 1, 3)),
   regexp_extract(i.i_item_id, '(\\d+)')
ORDER BY total_return_amount DESC
LIMIT 100
