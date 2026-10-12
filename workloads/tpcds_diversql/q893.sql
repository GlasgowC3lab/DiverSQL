WITH store_items AS (
    SELECT DISTINCT
        i.i_item_sk AS item_sk,
        i.i_product_name AS product_name,
        d.d_year,
        (
            SELECT SUM(cs.cs_ext_sales_price)
            FROM catalog_sales cs
            WHERE cs.cs_item_sk = i.i_item_sk
              AND cs.cs_sold_date_sk = d.d_date_sk
        ) AS total_catalog_sales
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
web_items AS (
    SELECT DISTINCT
        i.i_item_sk AS item_sk,
        i.i_product_name AS product_name,
        d.d_year,
        (
            SELECT SUM(cs.cs_ext_sales_price)
            FROM catalog_sales cs
            WHERE cs.cs_item_sk = i.i_item_sk
              AND cs.cs_sold_date_sk = d.d_date_sk
        ) AS total_catalog_sales
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
full_join_sales AS (
    SELECT
        COALESCE(ss.ss_item_sk, ws.ws_item_sk) AS item_sk,
        i.i_product_name AS product_name,
        d.d_year,
        (
            SELECT SUM(cs.cs_ext_sales_price)
            FROM catalog_sales cs
            WHERE cs.cs_item_sk = COALESCE(ss.ss_item_sk, ws.ws_item_sk)
              AND cs.cs_sold_date_sk = d.d_date_sk
        ) AS total_catalog_sales
    FROM store_sales ss
    FULL OUTER JOIN web_sales ws
        ON ss.ss_item_sk = ws.ws_item_sk
        AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
    JOIN item i ON i.i_item_sk = COALESCE(ss.ss_item_sk, ws.ws_item_sk)
    JOIN date_dim d ON d.d_date_sk = COALESCE(ss.ss_sold_date_sk, ws.ws_sold_date_sk)
    WHERE d.d_year = 2001
)
SELECT result.item_sk,
       result.product_name,
       result.d_year,
       result.total_catalog_sales
FROM (
    SELECT si.item_sk,
           si.product_name,
           si.d_year,
           si.total_catalog_sales
    FROM store_items si
    EXCEPT
    SELECT wi.item_sk,
           wi.product_name,
           wi.d_year,
           wi.total_catalog_sales
    FROM web_items wi

    UNION ALL

    SELECT fjs.item_sk,
           fjs.product_name,
           fjs.d_year,
           fjs.total_catalog_sales
    FROM full_join_sales fjs
) AS result
ORDER BY result.total_catalog_sales DESC
OFFSET 10 LIMIT 100
