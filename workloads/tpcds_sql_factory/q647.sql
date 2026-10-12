WITH item_aggregates AS (
    SELECT
        i.i_item_id AS i_id,
        i.i_product_name AS product_name,
        i.i_category AS category,
        i.i_brand AS brand,
        i.i_current_price AS current_price,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        AVG(cr.cr_net_loss) AS avg_net_loss,
        COUNT(*) AS return_transactions
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    GROUP BY i.i_item_id, i.i_product_name, i.i_category, i.i_brand, i.i_current_price
)
SELECT
    i_id,
    product_name,
    category,
    brand,
    current_price,
    total_return_amount,
    total_return_quantity,
    avg_net_loss,
    return_transactions,
    CASE
        WHEN current_price < 20 THEN 'Low'
        WHEN current_price BETWEEN 20 AND 100 THEN 'Medium'
        ELSE 'High'
    END AS price_bucket,
    DENSE_RANK() OVER (ORDER BY total_return_amount DESC) AS return_amount_rank,
    SUM(total_return_amount) OVER (
        PARTITION BY CASE
            WHEN current_price < 20 THEN 'Low'
            WHEN current_price BETWEEN 20 AND 100 THEN 'Medium'
            ELSE 'High'
        END
        ORDER BY total_return_amount DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_return_amount_by_bucket
FROM item_aggregates
WHERE total_return_amount > 0
ORDER BY total_return_amount DESC
LIMIT 10
