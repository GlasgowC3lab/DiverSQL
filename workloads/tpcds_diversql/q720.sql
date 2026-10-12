WITH sampled_sales AS (
        SELECT *
        FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    ),
    filtered_calls AS (
        SELECT cc_call_center_sk,
               cc_name,
               cc_city
        FROM call_center
        WHERE cc_city LIKE '%Hill%'
           OR cc_city LIKE 'First %'
    ),
    page_desc AS (
        SELECT cp_catalog_page_sk,
               cp_catalog_page_id,
               cp_description,
               regexp_extract(cp_description, '(\\b[Aa]reas\\b)', 1) AS extracted_word
        FROM catalog_page
        WHERE regexp_like(cp_description, '(?i)areas|legal|schools')
    ),
    subq1 AS (
        SELECT cs_order_number
        FROM sampled_sales s
        JOIN page_desc p ON s.cs_catalog_page_sk = p.cp_catalog_page_sk
        WHERE s.cs_net_profit > 500
          AND regexp_like(p.cp_description, '(?i)areas')
    ),
    subq2 AS (
        SELECT s.cs_order_number
        FROM sampled_sales s
        JOIN filtered_calls c ON s.cs_call_center_sk = c.cc_call_center_sk
        WHERE c.cc_city LIKE '%Hill%'
          AND s.cs_coupon_amt > 300
    )
SELECT
    p.cp_catalog_page_id,
    COUNT(DISTINCT s.cs_order_number)                         AS orders_cnt,
    SUM(s.cs_net_paid_inc_ship_tax)                           AS total_revenue,
    CASE
        WHEN SUM(s.cs_net_profit) > 10000 THEN 'HIGH'
        WHEN SUM(s.cs_net_profit) > 5000  THEN 'MEDIUM'
        ELSE 'LOW'
    END                                                       AS profit_category,
    CONCAT('City:', COALESCE(c.cc_city, 'UNKNOWN'))           AS city_info,
    SUBSTR(p.cp_description, 1, 30)                          AS description_snippet
FROM sampled_sales s
JOIN page_desc p ON s.cs_catalog_page_sk = p.cp_catalog_page_sk
LEFT JOIN filtered_calls c ON s.cs_call_center_sk = c.cc_call_center_sk
WHERE s.cs_order_number IN (
        SELECT cs_order_number FROM subq1
        INTERSECT
        SELECT cs_order_number FROM subq2
    )
GROUP BY
    p.cp_catalog_page_id,
    c.cc_city,
    p.cp_description
ORDER BY total_revenue DESC
LIMIT 100
