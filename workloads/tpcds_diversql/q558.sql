WITH
  sales_by_customer AS (
    SELECT
      cs.cs_bill_customer_sk AS customer_sk,
      cs.cs_sold_time_sk,
      cs.cs_net_profit,
      ca.ca_city,
      ca.ca_state,
      ca.ca_zip,
      ca.ca_street_type,
      hd.hd_demo_sk,
      hd.hd_buy_potential
    FROM catalog_sales cs
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE REGEXP_LIKE(ca.ca_street_type, '(Ave|Way)')
      AND ca.ca_zip LIKE '9%'
  ),

  morning_customers AS (
    SELECT DISTINCT ss.ss_customer_sk AS cust_sk
    FROM store_sales ss
    JOIN time_dim t
      ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour < 12
  ),

  circle_address_customers AS (
    SELECT DISTINCT cs.cs_bill_customer_sk AS cust_sk
    FROM catalog_sales cs
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_street_type = 'Circle'
  ),

  eligible_customers AS (
    SELECT cust_sk FROM morning_customers
    EXCEPT
    SELECT cust_sk FROM circle_address_customers
  ),

  intersect_demo AS (
    SELECT hd.hd_demo_sk
    FROM household_demographics hd
    JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound > 50000
    INTERSECT
    SELECT hd2.hd_demo_sk
    FROM household_demographics hd2
    WHERE hd2.hd_vehicle_count >= 2
  )
SELECT
  sbc.customer_sk,
  sbc.hd_buy_potential,
  loc.full_location,
  SUBSTRING(sbc.ca_zip, 1, 3) AS zip_prefix,
  sbc.cs_net_profit,
  CASE
    WHEN sbc.cs_net_profit > (
      SELECT MAX(ss_net_profit)
      FROM store_sales
      WHERE ss_store_sk = 620
    ) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS profit_category
FROM sales_by_customer sbc
JOIN eligible_customers ec
  ON sbc.customer_sk = ec.cust_sk
JOIN intersect_demo id
  ON sbc.hd_demo_sk = id.hd_demo_sk
CROSS JOIN LATERAL (
  SELECT CONCAT(sbc.ca_city, ', ', sbc.ca_state) AS full_location
) AS loc
WHERE REGEXP_EXTRACT(sbc.ca_city, '^([A-Za-z]+)') IS NOT NULL
ORDER BY sbc.cs_net_profit DESC
LIMIT 100
