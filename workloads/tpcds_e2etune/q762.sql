WITH cat_agg AS (
    SELECT
        cr_returned_date_sk AS date_sk,
        cr_warehouse_sk AS warehouse_sk,
        SUM(cr_return_amount) AS total_catalog_return_amount,
        SUM(cr_fee) AS total_catalog_fee,
        AVG(cr_fee) AS avg_catalog_fee,
        COUNT(*) AS cnt_catalog_returns
    FROM catalog_returns
    WHERE cr_fee > 20
    GROUP BY cr_returned_date_sk, cr_warehouse_sk
),
store_agg AS (
    SELECT
        sr_returned_date_sk AS date_sk,
        sr_store_sk AS store_sk,
        SUM(sr_return_amt) AS total_store_return_amount,
        SUM(sr_fee) AS total_store_fee,
        AVG(sr_fee) AS avg_store_fee,
        COUNT(*) AS cnt_store_returns
    FROM store_returns
    WHERE sr_fee > 20
    GROUP BY sr_returned_date_sk, sr_store_sk
)
SELECT
    ca.date_sk,
    ca.warehouse_sk,
    sa.store_sk,
    ca.total_catalog_return_amount,
    sa.total_store_return_amount,
    (ca.total_catalog_return_amount + sa.total_store_return_amount) AS total_return_amount,
    ca.cnt_catalog_returns,
    sa.cnt_store_returns,
    RANK() OVER (ORDER BY (ca.total_catalog_return_amount + sa.total_store_return_amount) DESC) AS return_rank
FROM cat_agg ca
JOIN store_agg sa
    ON ca.date_sk = sa.date_sk
WHERE ca.cnt_catalog_returns > 5
  AND sa.cnt_store_returns > 5
ORDER BY total_return_amount DESC
LIMIT 100
