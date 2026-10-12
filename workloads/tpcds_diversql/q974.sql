WITH
  intersect_customers AS (
    SELECT c_customer_id FROM customer WHERE c_birth_year >= 1975
    INTERSECT
    SELECT c_customer_id FROM customer WHERE c_preferred_cust_flag = 'Y'
  ),
  excluded_customers AS (
    SELECT c_customer_id FROM customer
    EXCEPT
    SELECT c.c_customer_id
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_quantity = 0
  ),
  sales_agg AS (
    SELECT
      p.p_promo_id AS dim_key,
      c.c_customer_id AS cust_key,
      SUM(cs.cs_net_paid_inc_ship) AS metric_amount
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE c.c_customer_id IN (SELECT c_customer_id FROM intersect_customers)
      AND c.c_customer_id NOT IN (SELECT c_customer_id FROM excluded_customers)
      AND c.c_customer_sk IN (SELECT sr_customer_sk FROM store_returns WHERE sr_net_loss > 500)
    GROUP BY CUBE (p.p_promo_id, c.c_customer_id)
  ),
  returns_agg AS (
    SELECT
      s.s_store_id AS dim_key,
      c.c_customer_id AS cust_key,
      SUM(sr.sr_net_loss) AS metric_amount
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_customer_id IN (SELECT c_customer_id FROM intersect_customers)
      AND c.c_customer_id NOT IN (SELECT c_customer_id FROM excluded_customers)
      AND c.c_customer_sk IN (SELECT cs_bill_customer_sk FROM catalog_sales WHERE cs_net_paid_inc_ship > 1000)
    GROUP BY CUBE (s.s_store_id, c.c_customer_id)
  )
SELECT
  dim_key,
  cust_key,
  metric_amount,
  (SELECT COUNT(*) FROM customer) AS total_customers
FROM sales_agg
UNION
SELECT
  dim_key,
  cust_key,
  metric_amount,
  (SELECT COUNT(*) FROM customer) AS total_customers
FROM returns_agg
LIMIT 100
