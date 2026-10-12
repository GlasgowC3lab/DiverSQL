WITH
  store_agg AS (
    SELECT
      ss.ss_sold_date_sk AS date_sk,
      ss.ss_store_sk AS store_sk,
      ss.ss_promo_sk AS promo_sk,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      SUM(ss.ss_net_profit) AS total_profit,
      CASE WHEN SUM(ss.ss_quantity) > 10 THEN 'Bulk' ELSE 'Regular' END AS sales_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ss.ss_sold_date_sk, ss.ss_store_sk, ss.ss_promo_sk
  ),
  web_agg AS (
    SELECT
      ws.ws_sold_date_sk AS date_sk,
      ws.ws_warehouse_sk AS warehouse_sk,
      ws.ws_promo_sk AS promo_sk,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      SUM(ws.ws_net_profit) AS total_profit,
      CASE WHEN SUM(ws.ws_quantity) > 10 THEN 'Bulk' ELSE 'Regular' END AS sales_type
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY ws.ws_sold_date_sk, ws.ws_warehouse_sk, ws.ws_promo_sk
  ),
  full_sales AS (
    SELECT
      COALESCE(s.date_sk, w.date_sk)        AS date_sk,
      s.store_sk,
      w.warehouse_sk,
      COALESCE(s.promo_sk, w.promo_sk)      AS promo_sk,
      s.total_sales                         AS store_sales,
      w.total_sales                         AS web_sales,
      s.sales_type
    FROM store_agg s
    FULL OUTER JOIN web_agg w
      ON s.date_sk = w.date_sk AND s.promo_sk = w.promo_sk
  ),
  union_sales AS (
    SELECT date_sk, store_sk, promo_sk, total_sales FROM store_agg
    UNION
    SELECT date_sk, NULL AS store_sk, promo_sk, total_sales FROM web_agg
  ),
  promo_intersect AS (
    SELECT ss_promo_sk AS promo_sk FROM store_sales
    INTERSECT
    SELECT ws_promo_sk FROM web_sales
  ),
  max_date_scalar AS (
    SELECT MAX(d_date) AS max_date FROM date_dim WHERE d_year = 2001
  )
SELECT
  result.date_sk,
  result.store_sk,
  result.warehouse_sk,
  result.sales_amount,
  CASE WHEN result.sales_amount > (SELECT AVG(total_sales) FROM store_agg) THEN 'Above Avg' ELSE 'Below Avg' END AS sales_category,
  (SELECT max_date FROM max_date_scalar) AS reference_date
FROM (
  SELECT
    f.date_sk,
    f.store_sk,
    f.warehouse_sk,
    COALESCE(f.store_sales, f.web_sales) AS sales_amount,
    f.promo_sk
  FROM full_sales f
  WHERE f.promo_sk IN (SELECT promo_sk FROM promo_intersect)
  UNION
  SELECT
    u.date_sk,
    u.store_sk,
    NULL AS warehouse_sk,
    u.total_sales AS sales_amount,
    u.promo_sk
  FROM union_sales u
  WHERE u.promo_sk IN (SELECT promo_sk FROM promo_intersect)
) AS result
ORDER BY result.sales_amount DESC
LIMIT 100
