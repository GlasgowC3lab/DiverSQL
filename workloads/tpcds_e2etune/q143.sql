WITH high_value_returns AS (
    SELECT *
    FROM store_returns
    WHERE sr_return_amt > 50
)
SELECT
    s.s_store_name,
    s.s_state,
    t.t_hour,
    hd.hd_vehicle_count,
    COUNT(*) AS return_cnt,
    SUM(hvr.sr_return_amt) AS total_return_amt,
    AVG(hvr.sr_net_loss) AS avg_net_loss,
    SUM(hvr.sr_net_loss) AS total_net_loss,
    SUM(hvr.sr_return_amt) / NULLIF(SUM(hvr.sr_return_quantity), 0) AS avg_return_amt_per_qty,
    ROUND(SUM(hvr.sr_net_loss) / NULLIF(SUM(hvr.sr_return_amt), 0), 4) AS loss_to_return_ratio
FROM high_value_returns hvr
JOIN time_dim t
  ON hvr.sr_return_time_sk = t.t_time_sk
JOIN household_demographics hd
  ON hvr.sr_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON hvr.sr_addr_sk = ca.ca_address_sk
JOIN store s
  ON hvr.sr_store_sk = s.s_store_sk
WHERE s.s_state = 'California'
  AND t.t_hour BETWEEN 9 AND 17
  AND hd.hd_buy_potential = 'High'
GROUP BY
    s.s_store_name,
    s.s_state,
    t.t_hour,
    hd.hd_vehicle_count
HAVING COUNT(*) >= 10
ORDER BY total_return_amt DESC
LIMIT 100
