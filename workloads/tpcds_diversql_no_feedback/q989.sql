WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_quantity,
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_class,
        cp.cp_department,
        cp.cp_description,
        CONCAT(i.i_brand, ' ', i.i_class) AS brand_class,
        REGEXP_EXTRACT(i.i_product_name, '(\\d{4,})') AS product_code
    FROM tpcds.catalog_sales cs
    JOIN tpcds.item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE REGEXP_LIKE(i.i_product_name, '(?i)bike')
      AND cp.cp_description LIKE '%2021%'
      AND SUBSTRING(i.i_product_name, 1, 5) = 'Ultra'
),
agg AS (
    SELECT
        brand_class,
        cp_department,
        SUM(cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM filtered_sales
    GROUP BY brand_class, cp_department
)
SELECT
    brand_class,
    cp_department,
    total_profit,
    sales_cnt,
    ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rn
FROM agg
ORDER BY total_profit DESC
LIMIT 100
