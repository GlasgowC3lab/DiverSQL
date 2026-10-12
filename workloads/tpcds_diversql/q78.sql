WITH returns_agg AS (
    SELECT
        sr_store_sk,
        COUNT(*) AS return_cnt,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_amt) AS avg_return_amt,
        MIN(sr_return_amt) AS min_return_amt,
        MAX(sr_return_amt) AS max_return_amt
    FROM
        tpcds.store_returns
    WHERE
        sr_return_ship_cost > 20.00
        AND sr_return_quantity > 1
        AND sr_hdemo_sk IN (161, 670)
        AND sr_cdemo_sk NOT IN (386838)
    GROUP BY
        sr_store_sk
),
stores_subset AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_state,
        s_market_id,
        s_rec_end_date,
        s_tax_percentage
    FROM
        tpcds.store
    WHERE
        s_state = 'TX'
        AND s_market_id = 5
        AND s_rec_end_date >= DATE '2000-03-12'
        AND s_tax_percentage < 5.00
),
diff_keys AS (
    SELECT sr_store_sk FROM tpcds.store_returns WHERE sr_return_amt > 0
    EXCEPT
    SELECT s_store_sk FROM tpcds.store WHERE s_state = 'CA'
)
SELECT
    COALESCE(stores_subset.s_store_sk, returns_agg.sr_store_sk) AS store_sk,
    stores_subset.s_store_name,
    stores_subset.s_state,
    stores_subset.s_market_id,
    stores_subset.s_rec_end_date,
    stores_subset.s_tax_percentage,
    returns_agg.return_cnt,
    returns_agg.total_return_amt,
    returns_agg.avg_return_amt,
    returns_agg.min_return_amt,
    returns_agg.max_return_amt
FROM
    returns_agg
FULL OUTER JOIN
    stores_subset
ON returns_agg.sr_store_sk = stores_subset.s_store_sk
LEFT JOIN
    diff_keys
ON diff_keys.sr_store_sk = COALESCE(stores_subset.s_store_sk, returns_agg.sr_store_sk)
WHERE
    diff_keys.sr_store_sk IS NOT NULL
ORDER BY
    total_return_amt DESC,
    store_sk
LIMIT 100
