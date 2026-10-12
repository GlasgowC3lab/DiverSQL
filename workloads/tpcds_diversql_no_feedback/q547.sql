WITH filtered_sales AS (
    SELECT
        cs.cs_net_paid,
        cs.cs_order_number,
        i.i_item_id,
        i.i_product_name,
        i.i_item_desc,
        i.i_brand,
        i.i_class,
        CONCAT(i.i_brand, '-', i.i_class) AS brand_class,
        regexp_extract(i.i_item_desc, '([0-9]{2,})', 1) AS extracted_digits
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '[0-9]{2}')
      AND i.i_product_name LIKE 'A%'
      AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_order_number = cs.cs_order_number
        )
)
SELECT
    i_item_id,
    i_product_name,
    i_item_desc,
    brand_class,
    extracted_digits,
    SUM(cs_net_paid) AS total_net_paid,
    COUNT(*) AS order_cnt
FROM filtered_sales
GROUP BY i_item_id, i_product_name, i_item_desc, brand_class, extracted_digits
ORDER BY total_net_paid DESC
LIMIT 100
