WITH agg_returns AS (
    SELECT
        ib.ib_income_band_sk,
        i.i_category,
        i.i_brand,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN income_band ib
        ON sr.sr_return_amt BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE i.i_manager_id IN (6, 18, 27)
      AND i.i_formulation LIKE '%moccasin%'
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ib.ib_income_band_sk, i.i_category, i.i_brand
    HAVING SUM(sr.sr_return_amt) > 500
)
SELECT
    a.ib_income_band_sk,
    a.i_category,
    a.i_brand,
    a.total_return_amt,
    a.total_return_qty,
    a.avg_return_amt,
    a.total_net_loss,
    RANK() OVER (PARTITION BY a.ib_income_band_sk ORDER BY a.total_return_amt DESC) AS category_rank
FROM agg_returns a
ORDER BY a.ib_income_band_sk, category_rank
LIMIT 100
