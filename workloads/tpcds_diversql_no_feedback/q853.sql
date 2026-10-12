WITH sales_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
filtered_sales AS (
    SELECT
        cs.cs_net_paid,
        i.i_category,
        i.i_brand,
        regexp_extract(i.i_item_desc, '(Premium|Deluxe)', 1) AS match_term
    FROM sales_sample cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE regexp_like(i.i_item_desc, '(?i)Premium|Deluxe')
      AND c.c_email_address LIKE '%@%\.com'
)
SELECT
    i_category,
    i_brand,
    match_term,
    SUM(cs_net_paid) AS total_net_paid,
    COUNT(*) AS sales_cnt
FROM filtered_sales
GROUP BY i_category, i_brand, match_term
ORDER BY total_net_paid DESC
LIMIT 100
