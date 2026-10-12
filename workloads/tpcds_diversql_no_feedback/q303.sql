WITH store_sales_agg AS (
    SELECT 
        cd.cd_gender AS gender,
        i.i_category AS category,
        SUM(ss.ss_ext_sales_price) AS sales_amount
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_ext_discount_amt > 500
    GROUP BY cd.cd_gender, i.i_category
),
catalog_sales_agg AS (
    SELECT 
        cd.cd_gender AS gender,
        i.i_category AS category,
        SUM(cs.cs_ext_sales_price) AS sales_amount
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_list_price > 100
    GROUP BY cd.cd_gender, i.i_category
),
union_all_sales AS (
    SELECT gender, category, sales_amount FROM store_sales_agg
    UNION ALL
    SELECT gender, category, sales_amount FROM catalog_sales_agg
)
SELECT DISTINCT
    ROW_NUMBER() OVER (ORDER BY combined.sales_amount DESC) AS row_num,
    combined.gender,
    combined.category,
    combined.sales_amount
FROM union_all_sales AS combined
WHERE EXISTS (
    SELECT 1
    FROM inventory inv
    JOIN item i2 ON inv.inv_item_sk = i2.i_item_sk
    WHERE i2.i_category = combined.category
      AND inv.inv_quantity_on_hand > 0
)
ORDER BY combined.sales_amount DESC
LIMIT 100
