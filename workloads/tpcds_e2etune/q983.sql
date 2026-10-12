WITH agg AS (
    SELECT
        sm.sm_code,
        sm.sm_type,
        COUNT(*) AS num_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        SUM(sr.sr_return_ship_cost) AS total_ship_cost,
        AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt_inc_tax
    FROM store_returns sr
    JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = ((sr.sr_store_sk % 5) + 1)
    WHERE sr.sr_return_ship_cost > 10.00
      AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
    GROUP BY sm.sm_code, sm.sm_type
    HAVING COUNT(*) > 50
)
SELECT
    sm_code,
    sm_type,
    num_returns,
    total_return_amt,
    avg_return_qty,
    total_ship_cost,
    avg_return_amt_inc_tax,
    ROW_NUMBER() OVER (ORDER BY total_return_amt DESC) AS rn
FROM agg
ORDER BY total_return_amt DESC
LIMIT 5
