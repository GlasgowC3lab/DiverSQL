WITH q1 AS (
   SELECT
       store.s_store_id,
       store.s_store_name,
       date_dim.d_quarter_name,
       COUNT(*) AS store_count
   FROM store
   FULL OUTER JOIN date_dim
       ON store.s_closed_date_sk = date_dim.d_date_sk
   WHERE date_dim.d_quarter_name = '1902Q2'
     AND store.s_state = 'TX'
   GROUP BY store.s_store_id, store.s_store_name, date_dim.d_quarter_name
),
q2 AS (
   SELECT
       store.s_store_id,
       store.s_store_name,
       date_dim.d_quarter_name,
       COUNT(*) AS store_count
   FROM store
   FULL OUTER JOIN date_dim
       ON store.s_closed_date_sk = date_dim.d_date_sk
   WHERE date_dim.d_quarter_name = '1903Q4'
     AND store.s_state = 'CA'
   GROUP BY store.s_store_id, store.s_store_name, date_dim.d_quarter_name
)
SELECT
    combined.s_store_id,
    combined.s_store_name,
    combined.d_quarter_name,
    combined.store_count
FROM (
    SELECT s_store_id, s_store_name, d_quarter_name, store_count FROM q1
    UNION ALL
    SELECT s_store_id, s_store_name, d_quarter_name, store_count FROM q2
) AS combined
ORDER BY combined.store_count DESC, combined.s_store_id
LIMIT 100
