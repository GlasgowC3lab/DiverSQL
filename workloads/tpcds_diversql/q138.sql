WITH sr_item AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt_inc_tax,
        sr.sr_return_tax,
        sr.sr_store_credit,
        -- create a small array from two numeric columns to unnest later
        ARRAY[ sr.sr_return_tax, sr.sr_return_amt_inc_tax ] AS metrics_array,
        i.i_brand,
        i.i_manager_id,
        i.i_manufact,
        i.i_rec_start_date
    FROM store_returns sr
    INNER JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE i.i_manager_id IN (11, 21, 41, 44, 98)
      AND i.i_manufact LIKE '%es%'
      AND i.i_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2002-12-31'
      AND sr.sr_return_tax > 2.00
      AND sr.sr_return_amt_inc_tax > 50.00
      AND sr.sr_store_credit < 100.00
)
SELECT
    sr_item.i_brand,
    sr_item.i_manager_id,
    sr_item.i_manufact,
    sr_item.sr_return_quantity,
    sr_item.sr_return_amt_inc_tax,
    metric,
    ROW_NUMBER() OVER (PARTITION BY sr_item.i_brand ORDER BY sr_item.sr_return_amt_inc_tax DESC) AS rn_by_brand,
    RANK() OVER (ORDER BY sr_item.sr_return_amt_inc_tax DESC) AS overall_rank
FROM sr_item
CROSS JOIN UNNEST(sr_item.metrics_array) AS t(metric)
WHERE metric > 10.00
ORDER BY overall_rank
LIMIT 100
