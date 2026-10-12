WITH catalog_metrics AS (
  SELECT
    d.d_year,
    d.d_quarter_name,
    sm.sm_type AS ship_type,
    w.w_state,
    SUM(cs.cs_ext_sales_price) AS cat_sales,
    SUM(cs.cs_ext_discount_amt) AS cat_discount,
    SUM(cs.cs_net_profit) AS cat_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS cat_return_amt,
    COUNT(DISTINCT cs.cs_bill_customer_sk) AS cat_distinct_cust,
    AVG(cs.cs_ext_discount_amt / NULLIF(cs.cs_ext_sales_price, 0)) AS cat_avg_discount_ratio
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_returns wr
    ON cs.cs_item_sk = wr.wr_item_sk
    AND cs.cs_sold_date_sk = wr.wr_returned_date_sk
  WHERE d.d_year BETWEEN 2001 AND 2003
    AND w.w_state IN ('CA', 'TX', 'NY')
  GROUP BY d.d_year, d.d_quarter_name, sm.sm_type, w.w_state
),
store_metrics AS (
  SELECT
    d.d_year,
    d.d_quarter_name,
    NULL AS ship_type,
    NULL AS w_state,
    SUM(ss.ss_ext_sales_price) AS store_sales,
    SUM(ss.ss_ext_discount_amt) AS store_discount,
    SUM(ss.ss_net_profit) AS store_profit,
    0 AS store_return_amt,
    COUNT(DISTINCT ss.ss_customer_sk) AS store_distinct_cust,
    AVG(ss.ss_ext_discount_amt / NULLIF(ss.ss_ext_sales_price, 0)) AS store_avg_discount_ratio
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year BETWEEN 2001 AND 2003
  GROUP BY d.d_year, d.d_quarter_name
)
SELECT
  COALESCE(cm.d_year, sm.d_year) AS year,
  COALESCE(cm.d_quarter_name, sm.d_quarter_name) AS quarter,
  cm.ship_type,
  cm.w_state,
  COALESCE(cm.cat_sales, 0) AS cat_sales,
  COALESCE(sm.store_sales, 0) AS store_sales,
  COALESCE(cm.cat_sales, 0) + COALESCE(sm.store_sales, 0) AS total_sales,
  COALESCE(cm.cat_discount, 0) + COALESCE(sm.store_discount, 0) AS total_discount,
  COALESCE(cm.cat_profit, 0) + COALESCE(sm.store_profit, 0) AS total_profit,
  COALESCE(cm.cat_return_amt, 0) AS total_return_amount,
  COALESCE(cm.cat_distinct_cust, 0) + COALESCE(sm.store_distinct_cust, 0) AS distinct_customers,
  CASE
    WHEN (COALESCE(cm.cat_sales, 0) + COALESCE(sm.store_sales, 0)) = 0 THEN NULL
    ELSE (COALESCE(cm.cat_avg_discount_ratio, 0) * COALESCE(cm.cat_sales, 0) +
          COALESCE(sm.store_avg_discount_ratio, 0) * COALESCE(sm.store_sales, 0))
         / (COALESCE(cm.cat_sales, 0) + COALESCE(sm.store_sales, 0))
  END AS avg_discount_ratio
FROM catalog_metrics cm
FULL OUTER JOIN store_metrics sm
  ON cm.d_year = sm.d_year
  AND cm.d_quarter_name = sm.d_quarter_name
WHERE (COALESCE(cm.cat_sales, 0) + COALESCE(sm.store_sales, 0)) > 200000
ORDER BY total_profit DESC
LIMIT 100
