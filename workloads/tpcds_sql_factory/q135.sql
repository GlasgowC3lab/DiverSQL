WITH sr_monthly AS (
    SELECT
        sr.sr_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_store_sk, d.d_year, d.d_month_seq
),
store_info AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_tax_percentage
    FROM store s
),
cc_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        AVG(cc.cc_tax_percentage) AS avg_cc_tax_pct
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    si.s_store_name,
    si.s_city,
    si.s_state,
    mr.d_year,
    mr.d_month_seq,
    mr.total_net_loss,
    mr.total_return_amt,
    mr.return_cnt,
    CASE WHEN mr.total_net_loss > 10000 THEN 'HIGH' ELSE 'NORMAL' END AS loss_category,
    RANK() OVER (PARTITION BY mr.d_year, mr.d_month_seq ORDER BY mr.total_net_loss DESC) AS net_loss_rank,
    AVG(mr.total_return_amt) OVER (PARTITION BY si.s_state) AS avg_state_return_amt,
    mr.total_net_loss * (1 + COALESCE(si.s_tax_percentage,0)/100) * (1 + COALESCE(cc.avg_cc_tax_pct,0)/100) AS net_loss_adj_tax,
    CASE WHEN mr.total_return_amt > 50000 THEN 'ALERT' ELSE 'OK' END AS return_alert
FROM sr_monthly mr
JOIN store_info si ON mr.sr_store_sk = si.s_store_sk
LEFT JOIN cc_monthly cc ON mr.d_year = cc.d_year AND mr.d_month_seq = cc.d_month_seq
ORDER BY mr.d_year, mr.d_month_seq, net_loss_rank
LIMIT 100
