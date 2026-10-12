WITH agg AS (
    SELECT
        cc.cc_state,
        COUNT(DISTINCT cc.cc_call_center_id) AS call_center_cnt,
        AVG(cc.cc_tax_percentage) AS avg_tax_pct,
        SUM(sr.sr_net_loss) AS total_net_loss,
        AVG(sr.sr_return_amt) AS avg_return_amt
    FROM call_center cc
    CROSS JOIN store_returns sr
    WHERE cc.cc_rec_end_date >= DATE '2000-01-01'
      AND cc.cc_tax_percentage > 0.05
      AND sr.sr_return_quantity > 1
      AND sr.sr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY cc.cc_state
)
SELECT
    cc_state,
    call_center_cnt,
    avg_tax_pct,
    total_net_loss,
    avg_return_amt,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
WHERE call_center_cnt > 0
ORDER BY loss_rank
LIMIT 20
