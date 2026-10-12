WITH returns_with_array AS (
    SELECT
        cr_returned_time_sk,
        cr_ship_mode_sk,
        cr_store_credit,
        cr_return_quantity,
        cr_return_amount,
        cr_fee,
        ARRAY[cr_return_amount, cr_fee] AS amt_fee_arr,
        cr_returned_date_sk
    FROM catalog_returns
    WHERE cr_ship_mode_sk = 13
      AND cr_store_credit > 30
      AND cr_return_quantity = 1
      AND cr_return_amount BETWEEN 10 AND 500
      AND cr_fee <= 100
      AND cr_returned_date_sk BETWEEN 2450000 AND 2450100
)
SELECT
    t.t_hour,
    t.t_shift,
    r.cr_ship_mode_sk,
    COUNT(*) AS returns_cnt,
    SUM(r.cr_return_amount) AS total_return_amount,
    AVG(r.cr_fee) AS avg_fee,
    MIN(r.cr_return_quantity) AS min_qty,
    MAX(r.cr_return_quantity) AS max_qty,
    SUM(u.val) AS sum_amt_fee_unwrapped
FROM returns_with_array r
JOIN time_dim t
    ON r.cr_returned_time_sk = t.t_time_sk
CROSS JOIN UNNEST(r.amt_fee_arr) AS u(val)
WHERE t.t_hour IN (2, 14, 19)
  AND t.t_second = 5
  AND t.t_shift = 'first'
GROUP BY t.t_hour, t.t_shift, r.cr_ship_mode_sk
ORDER BY total_return_amount DESC
LIMIT 100
