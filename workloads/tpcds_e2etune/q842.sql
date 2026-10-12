WITH agg AS (
    SELECT
        cc.cc_country AS country,
        cc.cc_state AS state,
        cc.cc_mkt_id AS mkt_id,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(*) AS total_rows
    FROM call_center cc
    CROSS JOIN store_returns sr
    WHERE cc.cc_country = 'United States'
      AND sr.sr_returned_date_sk BETWEEN 2451545 AND 2451910
      AND cc.cc_mkt_id IN (2, 3, 5)
    GROUP BY cc.cc_country, cc.cc_state, cc.cc_mkt_id
)
SELECT
    country,
    state,
    mkt_id,
    total_return_amt,
    avg_return_amt,
    total_return_qty,
    total_rows,
    RANK() OVER (ORDER BY total_return_amt DESC) AS state_return_rank
FROM agg
WHERE total_return_amt > 10000
ORDER BY state_return_rank
LIMIT 50
