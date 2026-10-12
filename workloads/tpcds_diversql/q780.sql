WITH
sr AS (
   SELECT
      sr.sr_store_sk,
      s.s_store_name,
      d.d_year,
      sr.sr_return_amt,
      r.r_reason_desc,
      CONCAT(s.s_city, ', ', s.s_state) AS store_location,
      CASE WHEN regexp_like(s.s_city, '^D.*') THEN 1 ELSE 0 END AS city_starts_with_D,
      SUBSTR(s.s_manager, 1, 5) AS manager_prefix
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE s.s_market_manager LIKE '%Stone%'
),
wr AS (
   SELECT
      wr.wr_reason_sk,
      r.r_reason_desc,
      d.d_year,
      wr.wr_return_amt,
      wr.wr_refunded_customer_sk,
      CASE WHEN regexp_like(CAST(wr.wr_refunded_customer_sk AS VARCHAR), '^[0-9]{6}$') THEN 1 ELSE 0 END AS six_digit_refund_id
   FROM web_returns wr
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE r.r_reason_desc LIKE '%damage%'
),
union_returns AS (
   SELECT sr.sr_store_sk AS store_sk, sr.sr_return_amt AS return_amt, sr.d_year AS d_year, sr.store_location, sr.city_starts_with_D
   FROM sr
   UNION
   SELECT NULL AS store_sk, wr.wr_return_amt AS return_amt, wr.d_year AS d_year, NULL AS store_location, NULL AS city_starts_with_D
   FROM wr
),
intersect_store_ids AS (
   SELECT sr.sr_store_sk AS store_sk FROM store_returns sr
   INTERSECT
   SELECT s.s_store_sk FROM store s
),
inv AS (
   SELECT i.inv_date_sk, i.inv_item_sk, i.inv_quantity_on_hand, d.d_year
   FROM inventory i
   JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
),
cs AS (
   SELECT cs.cs_sold_date_sk, cs.cs_item_sk, cs.cs_quantity, cs.cs_net_profit, d.d_year
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
),
full_join_inv_cs AS (
   SELECT
      COALESCE(inv.inv_date_sk, cs.cs_sold_date_sk) AS date_sk,
      COALESCE(inv.inv_item_sk, cs.cs_item_sk) AS item_sk,
      inv.inv_quantity_on_hand,
      cs.cs_quantity,
      cs.cs_net_profit,
      COALESCE(inv.d_year, cs.d_year) AS year
   FROM inv
   FULL OUTER JOIN cs
      ON inv.inv_date_sk = cs.cs_sold_date_sk
      AND inv.inv_item_sk = cs.cs_item_sk
),
ranked AS (
   SELECT
      f.date_sk,
      f.item_sk,
      f.inv_quantity_on_hand,
      f.cs_quantity,
      f.cs_net_profit,
      f.year,
      ROW_NUMBER() OVER (PARTITION BY f.year ORDER BY f.cs_net_profit DESC NULLS LAST) AS rnk
   FROM full_join_inv_cs f
   WHERE f.cs_net_profit IS NOT NULL
),
agg_union AS (
   SELECT d_year, SUM(return_amt) AS total_return_amt
   FROM union_returns
   GROUP BY d_year
),
store_flag AS (
   SELECT CASE WHEN EXISTS (SELECT 1 FROM intersect_store_ids) THEN 1 ELSE 0 END AS store_in_both
)
SELECT
   r.year,
   r.date_sk,
   r.item_sk,
   r.cs_quantity,
   r.cs_net_profit,
   r.inv_quantity_on_hand,
   r.rnk,
   COALESCE(a.total_return_amt, 0) AS total_return_amt,
   f.store_in_both
FROM ranked r
LEFT JOIN agg_union a ON r.year = a.d_year
CROSS JOIN store_flag f
WHERE r.rnk <= 5
ORDER BY r.year, r.rnk
LIMIT 100
