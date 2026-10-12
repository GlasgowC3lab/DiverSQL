WITH activity AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_product_name AS product_name,
        cp.cp_department AS department,
        'sale' AS activity_type,
        SUM(cs.cs_quantity) AS total_qty,
        SUM(cs.cs_ext_sales_price) AS total_amount
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_quantity > 10
      AND cp.cp_type = 'monthly'
    GROUP BY i.i_item_sk, i.i_product_name, cp.cp_department

    UNION ALL

    SELECT
        i.i_item_sk AS item_sk,
        i.i_product_name AS product_name,
        cp.cp_department AS department,
        'return' AS activity_type,
        SUM(cr.cr_return_quantity) AS total_qty,
        SUM(cr.cr_return_amount) AS total_amount
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_quantity > 5
      AND cp.cp_type = 'monthly'
    GROUP BY i.i_item_sk, i.i_product_name, cp.cp_department
)
SELECT
    a.item_sk,
    a.product_name,
    a.department,
    a.activity_type,
    a.total_qty,
    a.total_amount
FROM activity a
WHERE EXISTS (
    SELECT 1
    FROM promotion p
    WHERE p.p_item_sk = a.item_sk
      AND p.p_discount_active = 'Y'
)
ORDER BY a.total_amount DESC
LIMIT 100
