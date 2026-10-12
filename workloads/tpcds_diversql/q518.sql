WITH store_sales_agg AS (
  SELECT
    ss.ss_customer_sk AS customer_sk,
    d.d_date_sk AS date_sk,
    d.d_date,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ss.ss_net_profit) AS total_store_profit,
    CASE
      WHEN SUM(ss.ss_net_profit) > 10000 THEN 'HIGH'
      WHEN SUM(ss.ss_net_profit) > 0 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS store_profit_category
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  GROUP BY ss.ss_customer_sk, d.d_date_sk, d.d_date
),
web_sales_agg AS (
  SELECT
    ws.ws_bill_customer_sk AS customer_sk,
    d.d_date_sk AS date_sk,
    d.d_date,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(ws.ws_net_profit) AS total_web_profit,
    CASE
      WHEN SUM(ws.ws_net_profit) > 8000 THEN 'HIGH'
      WHEN SUM(ws.ws_net_profit) > 0 THEN 'MEDIUM'
      ELSE 'LOW'
    END AS web_profit_category
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  GROUP BY ws.ws_bill_customer_sk, d.d_date_sk, d.d_date
),
common_customers AS (
  SELECT ss_customer_sk AS customer_sk FROM store_sales
  INTERSECT
  SELECT ws_bill_customer_sk FROM web_sales
)
SELECT
  COALESCE(ssa.customer_sk, wsa.customer_sk) AS customer_sk,
  COALESCE(ssa.d_date, wsa.d_date) AS sale_date,
  ssa.total_store_sales,
  wsa.total_web_sales,
  CASE
    WHEN ssa.total_store_sales IS NULL THEN 'WEB_ONLY'
    WHEN wsa.total_web_sales IS NULL THEN 'STORE_ONLY'
    ELSE 'BOTH'
  END AS sales_source,
  promo.p_promo_name
FROM store_sales_agg ssa
FULL OUTER JOIN web_sales_agg wsa
  ON ssa.customer_sk = wsa.customer_sk
  AND ssa.date_sk = wsa.date_sk
LEFT JOIN common_customers cc
  ON cc.customer_sk = COALESCE(ssa.customer_sk, wsa.customer_sk)
LEFT JOIN LATERAL (
  SELECT p.p_promo_name
  FROM promotion p
  WHERE p.p_start_date_sk = COALESCE(ssa.date_sk, wsa.date_sk)
  ORDER BY p.p_promo_id
  LIMIT 1
) AS promo ON TRUE
WHERE COALESCE(ssa.customer_sk, wsa.customer_sk) IN (SELECT customer_sk FROM common_customers)
ORDER BY sale_date DESC, customer_sk
LIMIT 100
