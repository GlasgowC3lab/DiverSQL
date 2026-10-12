WITH
  store_color_returns AS (
    SELECT DISTINCT s.s_store_sk AS store_sk
    FROM store s
    JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%color%'
  ),
  store_service_returns AS (
    SELECT DISTINCT s.s_store_sk AS store_sk
    FROM store s
    JOIN store_returns sr ON s.s_store_sk = sr.sr_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%service%'
  ),
  stores_both_reasons AS (
    SELECT store_sk FROM store_color_returns
    INTERSECT
    SELECT store_sk FROM store_service_returns
  ),
  stores_color_only AS (
    SELECT store_sk FROM store_color_returns
    EXCEPT
    SELECT store_sk FROM store_service_returns
  ),
  customers_no_catalog AS (
    SELECT cd.cd_demo_sk AS customer_sk
    FROM customer_demographics cd
    WHERE NOT EXISTS (
      SELECT 1
      FROM catalog_returns cr
      WHERE cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    )
  ),
  full_join_store_returns AS (
    SELECT s.s_store_sk AS store_sk_s,
           sr.sr_store_sk AS store_sk_sr
    FROM store s
    FULL OUTER JOIN store_returns sr
      ON s.s_store_sk = sr.sr_store_sk
  )
SELECT id,
       category
FROM (
  SELECT store_sk AS id, 'BothReasons'      AS category FROM stores_both_reasons
  UNION ALL
  SELECT store_sk AS id, 'ColorOnly'       AS category FROM stores_color_only
  UNION ALL
  SELECT customer_sk AS id, 'NoCatalogReturns' AS category FROM customers_no_catalog
  UNION ALL
  SELECT COALESCE(store_sk_s, store_sk_sr) AS id,
         'FullStoreReturns' AS category
  FROM full_join_store_returns
) AS final_set
ORDER BY category, id
LIMIT 100
