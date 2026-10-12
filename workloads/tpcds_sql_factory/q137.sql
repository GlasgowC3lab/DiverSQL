WITH returns_by_month AS (
    SELECT
        sr.sr_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt) AS month_return_amt,
        SUM(sr.sr_return_quantity) AS month_return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_store_sk, d.d_year, d.d_month_seq
),
returns_with_rolling AS (
    SELECT
        rbm.sr_store_sk,
        rbm.d_year,
        rbm.d_month_seq,
        rbm.month_return_amt,
        rbm.month_return_qty,
        SUM(rbm.month_return_amt) OVER (PARTITION BY rbm.sr_store_sk ORDER BY rbm.d_year, rbm.d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3m_return_amt,
        AVG(rbm.month_return_amt) OVER (PARTITION BY rbm.sr_store_sk ORDER BY rbm.d_year, rbm.d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3m_avg_return_amt,
        ROW_NUMBER() OVER (PARTITION BY rbm.sr_store_sk ORDER BY rbm.d_year DESC, rbm.d_month_seq DESC) AS rn_desc
    FROM returns_by_month rbm
),
store_info AS (
    SELECT s.s_store_sk, s.s_store_name, s.s_city, s.s_state, s.s_tax_percentage
    FROM store s
),
call_center_monthly AS (
    SELECT
        cc.cc_division,
        d.d_year,
        d.d_month_seq,
        AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    GROUP BY cc.cc_division, d.d_year, d.d_month_seq
)
SELECT
    si.s_store_name,
    si.s_city,
    si.s_state,
    rw.d_year,
    rw.d_month_seq,
    rw.month_return_amt,
    rw.rolling_3m_return_amt,
    rw.rolling_3m_avg_return_amt,
    CASE 
        WHEN rw.rolling_3m_avg_return_amt > 5000 THEN 'ALERT'
        ELSE 'NORMAL'
    END AS return_alert,
    ccmt.avg_cc_tax_pct,
    rw.month_return_amt * (1 + COALESCE(si.s_tax_percentage,0)/100) AS tax_adjusted_return,
    (rw.month_return_amt * (1 + COALESCE(si.s_tax_percentage,0)/100)) - (rw.rolling_3m_avg_return_amt * (1 + COALESCE(ccmt.avg_cc_tax_pct,0)/100)) AS diff_vs_rolling_adj
FROM returns_with_rolling rw
JOIN store_info si ON rw.sr_store_sk = si.s_store_sk
LEFT JOIN call_center_monthly ccmt
    ON rw.d_year = ccmt.d_year
    AND rw.d_month_seq = ccmt.d_month_seq
WHERE rw.rn_desc = 1
ORDER BY rw.d_year DESC, rw.d_month_seq DESC, si.s_store_name
LIMIT 50
