WITH
item_info AS (
    SELECT i.i_item_sk,
           i.i_category,
           i.i_brand,
           i.i_product_name
    FROM item i
),
cs_agg AS (
    SELECT ii.i_category AS category,
           ii.i_brand AS brand,
           sum(cs.cs_net_paid) AS catalog_sales,
           array_agg(DISTINCT ii.i_product_name) AS product_names_arr,
           array_agg(DISTINCT ii.i_item_sk) AS item_sk_arr
    FROM catalog_sales cs
    JOIN item_info ii ON cs.cs_item_sk = ii.i_item_sk
    GROUP BY ii.i_category, ii.i_brand
),
ss_agg AS (
    SELECT ii.i_category AS category,
           ii.i_brand AS brand,
           sum(ss.ss_net_paid) AS store_sales
    FROM store_sales ss
    JOIN item_info ii ON ss.ss_item_sk = ii.i_item_sk
    GROUP BY ii.i_category, ii.i_brand
),
ws_agg AS (
    SELECT ii.i_category AS category,
           ii.i_brand AS brand,
           sum(ws.ws_net_paid) AS web_sales
    FROM web_sales ws
    JOIN item_info ii ON ws.ws_item_sk = ii.i_item_sk
    GROUP BY ii.i_category, ii.i_brand
),
combined AS (
    SELECT
        category,
        brand,
        cs.catalog_sales,
        ss.store_sales,
        ws.web_sales,
        cs.product_names_arr,
        cs.item_sk_arr
    FROM cs_agg cs
    FULL OUTER JOIN ss_agg ss USING (category, brand)
    FULL OUTER JOIN ws_agg ws USING (category, brand)
),
cat_str AS (
    SELECT
        category,
        brand,
        coalesce(catalog_sales, 0) AS catalog_sales,
        coalesce(store_sales, 0) AS store_sales,
        coalesce(web_sales, 0) AS web_sales,
        array_join(product_names_arr, ', ') AS product_names,
        array_join(item_sk_arr, ', ') AS item_sks
    FROM combined
)
SELECT *
FROM cat_str
