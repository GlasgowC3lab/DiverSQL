WITH
  return_customers AS (
    SELECT DISTINCT sr.sr_customer_sk AS cust_sk
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
  ),
  purchase_customers AS (
    SELECT DISTINCT cs.cs_bill_customer_sk AS cust_sk
    FROM catalog_sales cs
    JOIN date_dim d_pur ON cs.cs_sold_date_sk = d_pur.d_date_sk
    WHERE d_pur.d_year = 2001
  ),
  common_customers AS (
    SELECT cust_sk FROM purchase_customers
    INTERSECT
    SELECT cust_sk FROM return_customers
  )
SELECT
  unified.cust_sk,
  unified.year,
  COUNT(DISTINCT unified.order_number) AS orders_cnt,
  SUM(DISTINCT unified.ext_sales_price) AS distinct_sales_sum,
  SUM(DISTINCT unified.net_profit) AS distinct_profit_sum
FROM (
  SELECT
    cs.cs_bill_customer_sk AS cust_sk,
    cs.cs_order_number AS order_number,
    cs.cs_ext_sales_price AS ext_sales_price,
    cs.cs_net_profit AS net_profit,
    regexp_extract(sm.sm_contract, '(\\d+)', 1) AS contract_num,
    d.d_year AS year
  FROM catalog_sales cs
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE regexp_like(sm.sm_contract, '[A-Za-z]{2,}\\d')
    AND d.d_year = 2001

  UNION DISTINCT

  SELECT
    ws.ws_bill_customer_sk AS cust_sk,
    ws.ws_order_number AS order_number,
    ws.ws_ext_sales_price AS ext_sales_price,
    ws.ws_net_profit AS net_profit,
    regexp_extract(sm.sm_contract, '(\\d+)', 1) AS contract_num,
    d.d_year AS year
  FROM web_sales ws
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE sm.sm_contract LIKE '%e%'
    AND d.d_year = 2001
) AS unified
WHERE unified.cust_sk IN (SELECT cust_sk FROM common_customers)
GROUP BY unified.cust_sk, unified.year
ORDER BY distinct_sales_sum DESC
LIMIT 100
