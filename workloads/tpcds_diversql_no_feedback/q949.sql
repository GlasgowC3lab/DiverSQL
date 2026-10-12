WITH sales_customers AS (
    SELECT DISTINCT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_current_price > 100
),
returns_customers AS (
    SELECT DISTINCT
        sr.sr_customer_sk AS customer_sk,
        sr.sr_item_sk AS item_sk
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_rec_start_date >= DATE '2001-01-01'
      AND i.i_current_price > 100
)
SELECT
    customer_sk,
    item_sk
FROM sales_customers
EXCEPT
SELECT
    customer_sk,
    item_sk
FROM returns_customers
ORDER BY customer_sk, item_sk
LIMIT 100
