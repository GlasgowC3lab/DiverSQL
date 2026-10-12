WITH agg_all AS (
    SELECT
        s.s_store_id,
        r.r_reason_id,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_state = 'TX'
      AND sr.sr_return_amt_inc_tax > 100
    GROUP BY GROUPING SETS (
        (s.s_store_id, r.r_reason_id),
        (s.s_store_id),
        (r.r_reason_id),
        ()
    )
),
agg_filtered AS (
    SELECT
        s.s_store_id,
        r.r_reason_id,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE s.s_state = 'CA'
      AND sr.sr_return_amt_inc_tax > 500
    GROUP BY GROUPING SETS (
        (s.s_store_id, r.r_reason_id),
        (s.s_store_id),
        (r.r_reason_id),
        ()
    )
)
SELECT *
FROM agg_all
EXCEPT
SELECT *
FROM agg_filtered
ORDER BY total_return_amount DESC
LIMIT 100
