WITH sales_per_item AS (
    SELECT
        i.i_item_sk,
        i.i_class,
        i.i_category_id,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS transaction_count
    FROM catalog_sales cs
    FULL OUTER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE
        i.i_class IN ('accessories', 'furniture', 'decor')
        AND i.i_category_id BETWEEN 2 AND 9
        AND i.i_container <> 'Unknown'
        AND cs.cs_ship_addr_sk IN (5167051, 2000933, 989895)
        AND cs.cs_ext_discount_amt > 1000
        AND cs.cs_ship_hdemo_sk NOT IN (2685, 6730)
    GROUP BY i.i_item_sk, i.i_class, i.i_category_id
)
SELECT
    spi.i_class,
    AVG(spi.total_profit) AS avg_profit,
    SUM(spi.total_sales) AS sum_sales,
    COUNT(*) AS item_groups
FROM sales_per_item spi
GROUP BY spi.i_class
HAVING AVG(spi.total_profit) > (
    SELECT MAX(cs_ext_discount_amt) FROM catalog_sales
) / 10
ORDER BY avg_profit DESC
LIMIT 100
