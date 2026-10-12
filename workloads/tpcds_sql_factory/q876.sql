WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_refunded_cash,
        sr.sr_store_credit,
        c.c_preferred_cust_flag,
        td.t_shift
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_shift = 'Evening'
),
classified AS (
    SELECT
        fr.sr_store_sk,
        fr.c_preferred_cust_flag,
        CASE
            WHEN fr.sr_refunded_cash > 0 AND fr.sr_store_credit = 0 THEN 'Full Refund'
            WHEN fr.sr_refunded_cash = 0 AND fr.sr_store_credit > 0 THEN 'Store Credit'
            WHEN fr.sr_refunded_cash > 0 AND fr.sr_store_credit > 0 THEN 'Mixed'
            ELSE 'Other'
        END AS return_type
    FROM filtered_returns fr
),
type_counts AS (
    SELECT
        cl.sr_store_sk,
        cl.c_preferred_cust_flag,
        cl.return_type,
        COUNT(*) AS return_count
    FROM classified cl
    GROUP BY cl.sr_store_sk, cl.c_preferred_cust_flag, cl.return_type
),
store_totals AS (
    SELECT
        sr_store_sk,
        SUM(return_count) AS total_returns
    FROM type_counts
    GROUP BY sr_store_sk
),
store_full_refund_pct AS (
    SELECT
        tc.sr_store_sk,
        (SUM(CASE WHEN tc.return_type = 'Full Refund' THEN tc.return_count END) * 100.0) / st.total_returns AS full_refund_pct
    FROM type_counts tc
    JOIN store_totals st ON tc.sr_store_sk = st.sr_store_sk
    GROUP BY tc.sr_store_sk, st.total_returns
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_city,
    tc.c_preferred_cust_flag,
    tc.return_type,
    tc.return_count,
    (tc.return_count * 100.0) / st.total_returns AS pct_of_store,
    sfr.full_refund_pct,
    DENSE_RANK() OVER (ORDER BY sfr.full_refund_pct DESC) AS full_refund_pct_rank
FROM type_counts tc
JOIN store_totals st ON tc.sr_store_sk = st.sr_store_sk
JOIN store_full_refund_pct sfr ON tc.sr_store_sk = sfr.sr_store_sk
JOIN store s ON tc.sr_store_sk = s.s_store_sk
WHERE tc.return_type IN ('Full Refund', 'Store Credit')
ORDER BY s.s_store_id, tc.return_type
