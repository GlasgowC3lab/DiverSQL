WITH sales_orders AS (
    SELECT cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_call_center_sk IN (
        SELECT cc.cc_call_center_sk
        FROM call_center cc
        WHERE REGEXP_LIKE(cc.cc_name, 'Center')
          AND cc.cc_country = 'United States'
    )
),
returns_orders AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
),
orders_excluding_returns AS (
    SELECT cs_order_number FROM sales_orders
    EXCEPT
    SELECT cr_order_number FROM returns_orders
),
final_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ext_sales_price,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk
    FROM catalog_sales cs
    JOIN orders_excluding_returns ore ON cs.cs_order_number = ore.cs_order_number
    WHERE cs.cs_item_sk NOT IN (
        SELECT cs2.cs_item_sk
        FROM catalog_sales cs2
        WHERE cs2.cs_order_number = -1
    )
)
SELECT
    d.d_year,
    cc.cc_name,
    COUNT(DISTINCT fs.cs_bill_customer_sk) AS distinct_customers,
    SUM(DISTINCT fs.cs_ext_sales_price) AS distinct_sales_total,
    COUNT(DISTINCT p.p_promo_id) AS distinct_promos,
    CONCAT(cc.cc_city, ', ', cc.cc_state) AS location,
    SUBSTRING(p.p_promo_name, 1, 5) AS promo_prefix
FROM final_sales fs
JOIN date_dim d ON fs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p ON fs.cs_promo_sk = p.p_promo_sk
JOIN catalog_page cp ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND cp.cp_description LIKE '%discount%'
GROUP BY
    d.d_year,
    cc.cc_name,
    cc.cc_city,
    cc.cc_state,
    p.p_promo_name
ORDER BY distinct_sales_total DESC
LIMIT 100
