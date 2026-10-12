WITH full_sales AS (
  SELECT
    ss.ss_store_sk,
    s.s_store_name,
    ss.ss_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_indicator
  FROM store_sales ss
  FULL OUTER JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  WHERE ss.ss_ext_sales_price > 500
    AND EXISTS (
      SELECT 1 FROM customer c2
      WHERE c2.c_customer_sk = ss.ss_customer_sk
        AND c2.c_preferred_cust_flag = 'Y'
    )
),

array_expanded AS (
  SELECT
    fs.ss_store_sk,
    fs.s_store_name,
    val AS metric_value,
    fs.profit_indicator
  FROM full_sales fs
  CROSS JOIN UNNEST(ARRAY[fs.ss_ext_sales_price, fs.ss_net_profit]) AS t(val)
),

key_set AS (
  SELECT ss_customer_sk FROM store_sales
  EXCEPT
  SELECT c_customer_sk FROM customer
),

high_value_customers AS (
  SELECT
    kv.ss_customer_sk,
    COUNT(*) AS sales_count
  FROM key_set kv
  JOIN store_sales ss ON ss.ss_customer_sk = kv.ss_customer_sk
  WHERE ss.ss_ext_sales_price > 2000
  GROUP BY kv.ss_customer_sk
  HAVING COUNT(*) > 5
),

final_union AS (
  SELECT
    a.ss_store_sk AS store_key,
    a.s_store_name AS store_name,
    a.metric_value,
    a.profit_indicator,
    NULL AS sales_count
  FROM array_expanded a
  WHERE a.metric_value > 1000

  UNION ALL

  SELECT
    NULL AS store_key,
    NULL AS store_name,
    NULL AS metric_value,
    NULL AS profit_indicator,
    hvc.sales_count
  FROM high_value_customers hvc
)
SELECT *
FROM final_union
ORDER BY COALESCE(store_key, -1) ASC, sales_count DESC NULLS LAST
LIMIT 100
