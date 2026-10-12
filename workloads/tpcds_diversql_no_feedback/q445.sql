/*
  Goal: Identify the top 5 items by total return amount for each call center (where the call center key starts with '1'),
  using string‑based filters on numeric columns (via casting to VARCHAR), extracting the integer part of the sales price with a
  regular expression, and ranking the items per call center. The query joins catalog_returns to catalog_sales on the allowed keys,
  aggregates return and sales data, applies a LATERAL subquery for the regex extraction, and returns the result ordered and limited.
*/
WITH joined AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_call_center_sk,
        cr.cr_item_sk,
        cr.cr_order_number,
        cs.cs_sales_price,
        cs.cs_ext_tax
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_item_sk = cs.cs_item_sk
       AND cr.cr_order_number = cs.cs_order_number
    WHERE regexp_like(cast(cr.cr_return_amount AS varchar), '^[0-9]+\\.[0-9]{2}$')
      AND cast(cr.cr_call_center_sk AS varchar) LIKE '1%'
)
SELECT
    call_center,
    item_sk,
    total_return_amount,
    avg_sales_price,
    price_int_part,
    rn
FROM (
    SELECT
        j.cr_call_center_sk          AS call_center,
        j.cr_item_sk                AS item_sk,
        SUM(j.cr_return_amount)    AS total_return_amount,
        AVG(j.cs_sales_price)      AS avg_sales_price,
        l.price_int_part,
        ROW_NUMBER() OVER (PARTITION BY j.cr_call_center_sk ORDER BY SUM(j.cr_return_amount) DESC) AS rn
    FROM joined j
    JOIN LATERAL (
        SELECT regexp_extract(cast(j.cs_sales_price AS varchar), '(\\d+)', 1) AS price_int_part
    ) l ON true
    GROUP BY j.cr_call_center_sk, j.cr_item_sk, l.price_int_part
) sub
WHERE rn <= 5
ORDER BY call_center, total_return_amount DESC
LIMIT 100
