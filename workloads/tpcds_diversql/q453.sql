WITH
  cust_email_match AS (
    SELECT
      c.c_customer_sk,
      CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
      c.c_email_address,
      ca.ca_city,
      ib.ib_upper_bound AS income_upper,
      CASE WHEN ib.ib_upper_bound >= 80000 THEN 'High' ELSE 'Medium' END AS income_category
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
      AND c.c_first_name LIKE '%a%'
  ),
  cust_sales AS (
    SELECT
      ws.ws_bill_customer_sk AS c_customer_sk,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(*) AS orders,
      MIN(d.d_year) AS first_year,
      MAX(d.d_year) AS last_year,
      CASE WHEN SUM(ws.ws_ext_sales_price) > 10000 THEN 'VIP' ELSE 'Regular' END AS customer_type,
      regexp_extract(i.i_product_name, '(\\w+)\\s', 1) AS first_word_product
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_product_name LIKE '%Coat%'
    GROUP BY ws.ws_bill_customer_sk, i.i_product_name
  ),
  intersect_customers AS (
    SELECT c_customer_sk FROM cust_email_match
    INTERSECT
    SELECT c_customer_sk FROM cust_sales
  ),
  union_customers AS (
    SELECT c_customer_sk FROM intersect_customers
    UNION
    SELECT sr.sr_customer_sk FROM store_returns sr
    WHERE sr.sr_return_amt > 500
  ),
  ranked_customers AS (
    SELECT
      uc.c_customer_sk,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      RANK() OVER (PARTITION BY 1 ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM union_customers uc
    JOIN web_sales ws ON uc.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY uc.c_customer_sk
  )
SELECT
  rc.c_customer_sk,
  rc.total_sales,
  rc.sales_rank,
  ce.full_name,
  ce.income_category
FROM ranked_customers rc
LEFT JOIN cust_email_match ce ON rc.c_customer_sk = ce.c_customer_sk
ORDER BY rc.sales_rank
LIMIT 100
