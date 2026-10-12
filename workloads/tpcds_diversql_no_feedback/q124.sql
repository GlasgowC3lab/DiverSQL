/* goal: Combine store return performance metrics with a list of stores lacking returns, using a UNION ALL, while applying filters via IN subqueries and retaining all stores via a RIGHT OUTER JOIN */
WITH returns_by_store AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_store_sk = s.s_store_sk) AS total_return_rows,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM store s
    RIGHT OUTER JOIN store_returns sr
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_hdemo_sk IN (
        SELECT hd_demo_sk FROM household_demographics WHERE hd_vehicle_count > 2
    )
      AND s.s_state = 'CA'
    GROUP BY s.s_store_id, s.s_store_name, s.s_store_sk
)
SELECT
    s_store_id,
    s_store_name,
    total_return_amt,
    distinct_tickets,
    total_return_rows,
    avg_vehicle_count
FROM returns_by_store
UNION ALL
SELECT
    s.s_store_id,
    s.s_store_name,
    CAST(0 AS decimal(7,2)) AS total_return_amt,
    0 AS distinct_tickets,
    0 AS total_return_rows,
    NULL AS avg_vehicle_count
FROM store s
WHERE s.s_state = 'TX'
  AND s.s_store_id NOT IN (SELECT s_store_id FROM returns_by_store)
LIMIT 100
