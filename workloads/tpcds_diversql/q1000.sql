WITH sampled_sr AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
),
high_price_items AS (
    SELECT i_item_sk
    FROM item
    WHERE i_current_price > 100
),
store_keys_ca AS (
    SELECT sr.sr_store_sk
    FROM sampled_sr sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
),
store_keys_tx AS (
    SELECT sr.sr_store_sk
    FROM sampled_sr sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state = 'TX'
),
common_store_keys AS (
    SELECT sr_store_sk
    FROM store_keys_ca
    INTERSECT
    SELECT sr_store_sk
    FROM store_keys_tx
),
agg_ca AS (
    SELECT
        sr.sr_store_sk,
        d.d_year,
        SUM(sr.sr_net_loss) AS total_loss,
        CASE WHEN SUM(sr.sr_return_quantity) > 200 THEN 'HIGH' ELSE 'LOW' END AS volume_category
    FROM sampled_sr sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND d.d_year = 2001
      AND sr.sr_item_sk IN (SELECT i_item_sk FROM high_price_items)
      AND sr.sr_store_sk IN (SELECT sr_store_sk FROM common_store_keys)
    GROUP BY CUBE (sr.sr_store_sk, d.d_year)
),
agg_tx AS (
    SELECT
        sr.sr_store_sk,
        d.d_year,
        SUM(sr.sr_net_loss) AS total_loss,
        CASE WHEN SUM(sr.sr_return_quantity) > 200 THEN 'HIGH' ELSE 'LOW' END AS volume_category
    FROM sampled_sr sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_state = 'TX'
      AND d.d_year = 2001
      AND sr.sr_item_sk IN (SELECT i_item_sk FROM high_price_items)
      AND sr.sr_store_sk IN (SELECT sr_store_sk FROM common_store_keys)
    GROUP BY CUBE (sr.sr_store_sk, d.d_year)
),
combined AS (
    SELECT 'CA' AS region, sr_store_sk, d_year, total_loss, volume_category
    FROM agg_ca
    UNION ALL
    SELECT 'TX' AS region, sr_store_sk, d_year, total_loss, volume_category
    FROM agg_tx
)
SELECT region,
       sr_store_sk,
       d_year,
       total_loss,
       volume_category
FROM combined
ORDER BY total_loss DESC
OFFSET 0 LIMIT 20
