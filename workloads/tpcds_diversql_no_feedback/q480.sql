WITH sales_keys AS (
    SELECT DISTINCT
        c.c_customer_sk AS customer_sk,
        c.c_customer_id AS customer_id,
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE i.i_item_desc LIKE '%BLACK%'
      AND regexp_like(i.i_item_desc, '[A-Z]{3}[0-9]{2}')
      AND d.d_year = 2000
),
returns_keys AS (
    SELECT DISTINCT
        c.c_customer_sk AS customer_sk,
        c.c_customer_id AS customer_id,
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
),
non_returned AS (
    SELECT customer_sk, customer_id, item_sk, item_id, item_desc
    FROM sales_keys
    EXCEPT
    SELECT customer_sk, customer_id, item_sk, item_id, item_desc
    FROM returns_keys
)
SELECT
    nr.customer_id,
    nr.item_id,
    concat('Customer-', nr.customer_id) AS customer_label,
    concat('Item-', nr.item_id) AS item_label,
    regexp_extract(nr.item_desc, '^(\\w+)', 1) AS first_word_desc,
    substring(nr.item_desc, 1, 10) AS short_desc,
    count(*) OVER (PARTITION BY nr.customer_id) AS distinct_items_per_customer
FROM non_returned nr
ORDER BY distinct_items_per_customer DESC, nr.customer_id
LIMIT 100
