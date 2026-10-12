WITH
    item_inventory AS (
        SELECT
            it.i_item_sk,
            it.i_item_id,
            it.i_product_name,
            it.i_category,
            i.inv_quantity_on_hand
        FROM inventory i
        FULL OUTER JOIN item it
            ON i.inv_item_sk = it.i_item_sk
        WHERE i.inv_quantity_on_hand > 0 OR i.inv_quantity_on_hand IS NULL
    ),
    sales_with_promos AS (
        SELECT
            ii.i_item_id,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            lp.promo_cnt,
            (SELECT AVG(ss2.ss_ext_sales_price) FROM store_sales ss2) AS avg_store_sales
        FROM item_inventory ii
        JOIN store_sales ss
            ON ss.ss_item_sk = ii.i_item_sk
        LEFT JOIN LATERAL (
            SELECT COUNT(*) AS promo_cnt
            FROM promotion p
            WHERE p.p_item_sk = ii.i_item_sk
              AND p.p_discount_active = 'Y'
        ) lp ON TRUE
        WHERE EXISTS (
            SELECT 1 FROM promotion p2
            WHERE p2.p_promo_sk = ss.ss_promo_sk
              AND p2.p_discount_active = 'Y'
        )
        GROUP BY ii.i_item_id, lp.promo_cnt
    ),
    catalog_sales_set AS (
        SELECT
            ii.i_item_id,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            lp.promo_cnt,
            (SELECT AVG(cs2.cs_ext_sales_price) FROM catalog_sales cs2) AS avg_catalog_sales
        FROM item_inventory ii
        JOIN catalog_sales cs
            ON cs.cs_item_sk = ii.i_item_sk
        LEFT JOIN LATERAL (
            SELECT COUNT(*) AS promo_cnt
            FROM promotion p
            WHERE p.p_item_sk = ii.i_item_sk
              AND p.p_discount_active = 'Y'
        ) lp ON TRUE
        GROUP BY ii.i_item_id, lp.promo_cnt
    ),
    combined AS (
        SELECT i_item_id FROM sales_with_promos
        UNION ALL
        SELECT i_item_id FROM catalog_sales_set
    )
SELECT i_item_id
FROM combined
EXCEPT
SELECT DISTINCT i.i_item_id
FROM web_returns wr
JOIN item i
    ON i.i_item_sk = wr.wr_item_sk
WHERE wr.wr_return_amt > 0
LIMIT 100
