WITH store_return_agg AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_amt) AS store_return_amount,
        SUM(sr_return_quantity) AS store_return_quantity,
        AVG(sr_fee) AS avg_store_fee
    FROM store_returns
    WHERE sr_return_amt > 10
    GROUP BY sr_item_sk
)
SELECT
    cr.cr_item_sk,
    cr.cr_returned_date_sk,
    COUNT(*) AS catalog_return_cnt,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    sr.store_return_amount,
    sr.store_return_quantity,
    SUM(cr.cr_return_amount) + sr.store_return_amount AS combined_return_amount,
    AVG(cr.cr_fee) AS avg_catalog_fee,
    sr.avg_store_fee
FROM catalog_returns cr
JOIN store_return_agg sr
    ON cr.cr_item_sk = sr.sr_item_sk
WHERE cr.cr_return_amount > 30
    AND cr.cr_warehouse_sk IN (7, 12, 14)
GROUP BY
    cr.cr_item_sk,
    cr.cr_returned_date_sk,
    sr.store_return_amount,
    sr.store_return_quantity,
    sr.avg_store_fee
HAVING SUM(cr.cr_return_amount) > 500
ORDER BY combined_return_amount DESC
LIMIT 50
