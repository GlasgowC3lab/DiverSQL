SELECT
    r.r_reason_desc,
    d.d_year,
    d.d_quarter_seq,
    s.s_market_desc,
    COUNT(*) AS total_returns,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_net_loss) AS avg_net_loss,
    approx_percentile(sr.sr_return_amt, 0.5) AS median_return_amount,
    RANK() OVER (PARTITION BY d.d_year, d.d_quarter_seq ORDER BY AVG(sr.sr_net_loss) DESC) AS net_loss_reason_rank,
    CASE 
        WHEN SUM(sr.sr_return_amt) > 500000 THEN 'High Volume'
        ELSE 'Normal Volume'
    END AS volume_category
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
WHERE d.d_year >= 2019
  AND (s.s_closed_date_sk IS NULL OR d.d_date_sk <= s.s_closed_date_sk)
GROUP BY r.r_reason_desc, d.d_year, d.d_quarter_seq, s.s_market_desc
HAVING COUNT(*) >= 10
ORDER BY d.d_year, d.d_quarter_seq, net_loss_reason_rank
