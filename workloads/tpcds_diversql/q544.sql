WITH
    intersect_items AS (
        SELECT inv_item_sk AS i_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 500
        INTERSECT
        SELECT ss_item_sk
        FROM store_sales
        WHERE ss_ext_sales_price > 5000
    ),
    item_sales AS (
        SELECT
            i.i_item_sk,
            i.i_brand,
            i.i_brand_id,
            i.i_current_price,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            SUM(ss.ss_net_profit) AS total_profit,
            COUNT(*) AS sales_cnt
        FROM store_sales ss
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        WHERE
            i.i_brand_id IN (8015002, 3001002, 10008011)
            AND i.i_rec_end_date > DATE '2000-01-01'
            AND ss.ss_quantity > 1
            AND ss.ss_ext_sales_price > 1000
        GROUP BY
            i.i_item_sk,
            i.i_brand,
            i.i_brand_id,
            i.i_current_price
    )
SELECT
    isales.i_item_sk,
    isales.i_brand,
    isales.i_brand_id,
    isales.total_sales,
    isales.total_profit,
    CASE
        WHEN isales.total_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status,
    inv.inv_quantity_on_hand,
    inv.inv_warehouse_sk,
    (isales.i_current_price - (SELECT AVG(i_current_price) FROM item)) AS price_vs_avg,
    RANK() OVER (PARTITION BY isales.i_brand ORDER BY isales.total_sales DESC) AS brand_sales_rank,
    ROW_NUMBER() OVER (ORDER BY isales.total_sales DESC) AS overall_rank
FROM item_sales isales
JOIN inventory inv
    ON inv.inv_item_sk = isales.i_item_sk
JOIN intersect_items ii
    ON ii.i_item_sk = isales.i_item_sk
WHERE
    inv.inv_warehouse_sk IN (3, 4, 11)
    AND inv.inv_quantity_on_hand BETWEEN 200 AND 800
    AND isales.sales_cnt >= 5
ORDER BY brand_sales_rank, isales.i_item_sk
LIMIT 100
