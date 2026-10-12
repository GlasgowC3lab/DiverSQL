/*
Goal: Identify store locations and time slots (hour + AM/PM) with substantial return activity, compute aggregate return amounts and average fees, filter to stores without any very high‑fee returns, and compare the average fee to the maximum fee observed for a specific store.
*/
WITH base AS (
    SELECT
        sr.sr_store_sk,
        t.t_hour,
        t.t_am_pm,
        sr.sr_fee,
        sr.sr_store_credit,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_ticket_number
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_fee > 10
        AND sr.sr_store_credit < 100
        AND t.t_minute IN (0, 5, 10, 16)
        AND t.t_am_pm = 'PM'
        AND sr.sr_store_sk IN (640, 466)
        AND sr.sr_return_quantity > 0
),
agg1 AS (
    SELECT
        sr_store_sk,
        t_hour,
        t_am_pm,
        COUNT(*) AS cnt_returns,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_fee) AS avg_fee
    FROM base
    GROUP BY sr_store_sk, t_hour, t_am_pm
    HAVING COUNT(*) >= 5
),
max_fee_scalar AS (
    SELECT MAX(sr_fee) AS max_fee FROM store_returns WHERE sr_store_sk = 640
)
SELECT
    a.sr_store_sk,
    a.t_hour,
    a.t_am_pm,
    a.cnt_returns,
    a.total_return_amt,
    a.avg_fee,
    mf.max_fee
FROM agg1 a
CROSS JOIN max_fee_scalar mf
WHERE a.avg_fee > mf.max_fee
    AND NOT EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_store_sk = a.sr_store_sk
          AND sr2.sr_fee > 500
    )
ORDER BY a.total_return_amt DESC
LIMIT 100
