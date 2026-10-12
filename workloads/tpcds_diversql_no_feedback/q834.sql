/*
Goal: Calculate total and average return amounts, counts, and shipping‑cost statistics per return reason and, when applicable, per store. The query focuses on higher‑value returns, modest store‑credit refunds, small return quantities, and a subset of specific return reasons.
*/
WITH sr_pre AS (
    SELECT
        sr_reason_sk,
        sr_store_sk,
        SUM(sr_return_amt)        AS sum_return_amt,
        AVG(sr_return_amt)        AS avg_return_amt,
        COUNT(*)                  AS return_cnt,
        MIN(sr_return_ship_cost)  AS min_ship_cost,
        MAX(sr_return_ship_cost)  AS max_ship_cost
    FROM store_returns
    WHERE sr_return_ship_cost > 100.00                -- high shipping cost
      AND sr_store_credit      < 50.00                -- modest store credit
      AND sr_return_quantity BETWEEN 1 AND 5           -- small return quantities
      AND sr_return_amt       >= 200.00               -- high return amount
    GROUP BY sr_reason_sk, sr_store_sk
)
SELECT
    r.r_reason_desc,
    sr_pre.sr_store_sk,
    SUM(sr_pre.sum_return_amt) AS total_return_amt,
    AVG(sr_pre.avg_return_amt) AS avg_return_amt,
    SUM(sr_pre.return_cnt)     AS total_returns,
    MIN(sr_pre.min_ship_cost)  AS min_ship_cost,
    MAX(sr_pre.max_ship_cost)  AS max_ship_cost
FROM sr_pre
JOIN reason r
  ON sr_pre.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_id IN ('AAAAAAAACAAAAAAA', 'AAAAAAAALAAAAAAA')
GROUP BY GROUPING SETS (
    (r.r_reason_desc),
    (r.r_reason_desc, sr_pre.sr_store_sk)
)
ORDER BY total_return_amt DESC
LIMIT 100
