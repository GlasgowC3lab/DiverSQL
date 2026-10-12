SELECT
    s.s_store_id,
    d.d_date,
    s.s_city,
    s.s_state,
    CASE 
        WHEN s.s_floor_space >= 50000 THEN 'Large'
        WHEN s.s_floor_space >= 20000 THEN 'Medium'
        ELSE 'Small'
    END AS store_tier,
    sr.sr_net_loss,
    SUM(sr.sr_net_loss) OVER (PARTITION BY s.s_store_id ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_loss,
    AVG(sr.sr_net_loss) OVER (PARTITION BY s.s_store_id ORDER BY d.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_avg_net_loss,
    SUM(sr.sr_return_quantity) OVER (PARTITION BY s.s_store_id ORDER BY d.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7day_return_qty
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE d.d_year BETWEEN 2018 AND 2022
  AND (s.s_closed_date_sk IS NULL OR d.d_date_sk <= s.s_closed_date_sk)
ORDER BY s.s_store_id, d.d_date
