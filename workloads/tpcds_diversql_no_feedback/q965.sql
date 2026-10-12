WITH recent_sales AS (
   SELECT ss.ss_item_sk
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
)
SELECT
   return_type,
   return_date,
   store_name,
   reason_desc,
   return_amount,
   CASE WHEN return_amount > 100 THEN 'High' ELSE 'Low' END AS amount_category
FROM (
   SELECT
      'Store' AS return_type,
      d.d_date AS return_date,
      s.s_store_name AS store_name,
      r.r_reason_desc AS reason_desc,
      sr.sr_return_amt AS return_amount,
      sr.sr_item_sk
   FROM store_returns sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   WHERE EXISTS (
         SELECT 1 FROM recent_sales rs WHERE rs.ss_item_sk = sr.sr_item_sk
       )
     AND d.d_year = 2001
   UNION ALL
   SELECT
      'Catalog' AS return_type,
      d.d_date AS return_date,
      NULL AS store_name,
      r.r_reason_desc AS reason_desc,
      cr.cr_return_amount AS return_amount,
      cr.cr_item_sk
   FROM catalog_returns cr
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE EXISTS (
         SELECT 1 FROM recent_sales rs WHERE rs.ss_item_sk = cr.cr_item_sk
       )
     AND d.d_year = 2001
) AS combined
ORDER BY return_date DESC, return_amount DESC
LIMIT 100
