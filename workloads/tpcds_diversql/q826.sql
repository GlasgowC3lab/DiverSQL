WITH
  -- Customers from Ukraine with high list price
  cust_a AS (
    SELECT DISTINCT cs.cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country = 'UKRAINE'
      AND cs.cs_list_price > 50
  ),
  -- Customers who shipped with UPS
  cust_b AS (
    SELECT DISTINCT cs.cs_ship_customer_sk AS cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier = 'UPS'
  ),
  -- Intersection of the two customer sets
  common_cust AS (
    SELECT cs_bill_customer_sk FROM cust_a
    INTERSECT
    SELECT cs_bill_customer_sk FROM cust_b
  ),
  -- Union of two sales subsets to create duplicate‑free rows for later aggregation
  union_sales AS (
    SELECT cs.cs_ship_mode_sk, cs.cs_ext_sales_price
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1000
    UNION
    SELECT cs.cs_ship_mode_sk, cs.cs_ext_sales_price
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
  ),
  agg_union AS (
    SELECT cs_ship_mode_sk,
           SUM(cs_ext_sales_price) AS total_sales,
           COUNT(*)               AS txn_count
    FROM union_sales
    GROUP BY cs_ship_mode_sk
  ),
  -- Build an array of ship mode codes per ship mode
  ship_mode_arrays AS (
    SELECT sm.sm_ship_mode_sk,
           ARRAY_AGG(sm.sm_code) AS codes
    FROM ship_mode sm
    GROUP BY sm.sm_ship_mode_sk
  ),
  -- Unnest the arrays so each code appears on its own row
  ship_mode_unnest AS (
    SELECT sma.sm_ship_mode_sk,
           code
    FROM ship_mode_arrays sma
    CROSS JOIN UNNEST(sma.codes) AS t(code)
  )
SELECT
  cp.cp_department,
  sm.sm_carrier,
  c.c_birth_country,
  COUNT(DISTINCT cs.cs_order_number)            AS orders,
  SUM(cs.cs_ext_sales_price)                    AS total_sales,
  AVG(cs.cs_ext_discount_amt)                  AS avg_discount,
  MIN(cs.cs_ext_sales_price)                   AS min_sales,
  MAX(cs.cs_ext_sales_price)                   AS max_sales,
  agg_u.total_sales                             AS union_total_sales,
  agg_u.txn_count                               AS union_txn_count,
  su.code                                       AS ship_mode_code
FROM catalog_sales cs
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN common_cust cc ON cs.cs_bill_customer_sk = cc.cs_bill_customer_sk
JOIN agg_union agg_u ON sm.sm_ship_mode_sk = agg_u.cs_ship_mode_sk
JOIN ship_mode_unnest su ON sm.sm_ship_mode_sk = su.sm_ship_mode_sk
WHERE c.c_birth_country = 'CHILE'
  AND cs.cs_list_price > 30
  AND sm.sm_carrier = 'FEDEX'
  AND cs.cs_list_price > (
        SELECT MAX(cs2.cs_list_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_ship_mode_sk = 2
      )
GROUP BY
  cp.cp_department,
  sm.sm_carrier,
  c.c_birth_country,
  agg_u.total_sales,
  agg_u.txn_count,
  su.code
HAVING SUM(cs.cs_ext_sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 100
