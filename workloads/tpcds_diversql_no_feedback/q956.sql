WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    w.w_state,
    ib.ib_income_band_sk,
    c.c_salutation,
    sm.sm_type,
    SUM(sr.cr_return_amount) AS total_return_amount,
    AVG(sr.cr_fee) AS avg_fee,
    COUNT(*) AS return_cnt,
    MAX(sr.cr_return_ship_cost) AS max_ship_cost,
    MIN(sr.cr_return_quantity) AS min_quantity
FROM sampled_returns sr
JOIN item i
    ON sr.cr_item_sk = i.i_item_sk
JOIN warehouse w
    ON sr.cr_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm
    ON sr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c
    ON sr.cr_refunded_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON sr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN inventory inv
    ON i.i_item_sk = inv.inv_item_sk
   AND w.w_warehouse_sk = inv.inv_warehouse_sk
WHERE
    sr.cr_return_amount > 500.00
    AND sr.cr_fee BETWEEN 20.00 AND 80.00
    AND w.w_gmt_offset = -5.00
    AND c.c_salutation = 'Ms.'
    AND ib.ib_upper_bound <= 50000
GROUP BY ROLLUP (w.w_state, ib.ib_income_band_sk, c.c_salutation, sm.sm_type)
ORDER BY total_return_amount DESC
LIMIT 100
