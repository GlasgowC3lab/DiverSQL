WITH store_ret AS (
   SELECT
       sr.sr_store_sk,
       sr.sr_returned_date_sk,
       sr.sr_return_amt,
       sr.sr_fee,
       sr.sr_return_ship_cost,
       d.d_year,
       s.s_store_name,
       ARRAY[sr.sr_fee, sr.sr_return_ship_cost] AS fee_array
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   WHERE d.d_year = 2001
),
catalog_ret AS (
   SELECT
       cr.cr_call_center_sk,
       cr.cr_returned_date_sk,
       cr.cr_return_amount,
       cr.cr_fee,
       cr.cr_return_ship_cost,
       d.d_year,
       cc.cc_name,
       ARRAY[cr.cr_fee, cr.cr_return_ship_cost] AS fee_array
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   WHERE d.d_year = 2001
),
combined AS (
   SELECT
       sr.s_store_name AS entity_name,
       sr.d_year,
       sr.sr_return_amt AS return_amount,
       v.fee_type,
       t.fee_value
   FROM store_ret sr
   CROSS JOIN UNNEST(sr.fee_array) WITH ORDINALITY AS t(fee_value, pos)
   CROSS JOIN (VALUES (1, 'fee'), (2, 'ship_cost')) AS v(pos, fee_type)
   WHERE t.pos = v.pos
   UNION ALL
   SELECT
       cr.cc_name AS entity_name,
       cr.d_year,
       cr.cr_return_amount AS return_amount,
       v.fee_type,
       t.fee_value
   FROM catalog_ret cr
   CROSS JOIN UNNEST(cr.fee_array) WITH ORDINALITY AS t(fee_value, pos)
   CROSS JOIN (VALUES (1, 'fee'), (2, 'ship_cost')) AS v(pos, fee_type)
   WHERE t.pos = v.pos
),
agg AS (
   SELECT
       entity_name,
       d_year,
       fee_type,
       SUM(return_amount) AS total_return_amount,
       SUM(fee_value) AS total_fee
   FROM combined
   GROUP BY GROUPING SETS ((entity_name, d_year, fee_type), (entity_name, d_year))
)
SELECT
   entity_name,
   d_year,
   fee_type,
   total_return_amount,
   total_fee,
   rn
FROM (
   SELECT
       entity_name,
       d_year,
       fee_type,
       total_return_amount,
       total_fee,
       ROW_NUMBER() OVER (PARTITION BY entity_name, d_year ORDER BY total_return_amount DESC) AS rn
   FROM agg
) ranked
WHERE rn <= 5
ORDER BY entity_name, d_year, total_return_amount DESC
LIMIT 100
