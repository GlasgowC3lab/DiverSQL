WITH monthly_store_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_moy,
        d.d_current_month,
        SUM(sr.sr_return_amt) AS monthly_return_amt,
        COUNT(*) AS return_transactions,
        AVG(sr.sr_return_amt) AS avg_return_amt
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_moy, d.d_current_month
)
SELECT
    msr.s_store_id,
    msr.s_store_name,
    msr.d_year,
    msr.d_moy AS month,
    msr.monthly_return_amt,
    msr.return_transactions,
    msr.avg_return_amt,
    SUM(msr.monthly_return_amt) OVER (PARTITION BY msr.s_store_id ORDER BY msr.d_year, msr.d_moy ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amt,
    msr.monthly_return_amt - LAG(msr.monthly_return_amt) OVER (PARTITION BY msr.s_store_id ORDER BY msr.d_year, msr.d_moy) AS mom_change,
    CASE
        WHEN msr.monthly_return_amt - LAG(msr.monthly_return_amt) OVER (PARTITION BY msr.s_store_id ORDER BY msr.d_year, msr.d_moy) > 0 THEN 'Increase'
        WHEN msr.monthly_return_amt - LAG(msr.monthly_return_amt) OVER (PARTITION BY msr.s_store_id ORDER BY msr.d_year, msr.d_moy) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS change_indicator
FROM monthly_store_returns msr
ORDER BY msr.s_store_id, msr.d_year, msr.d_moy
