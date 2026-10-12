SELECT sm.sm_type,
       sm.sm_carrier,
       td.t_hour,
       hd_ret.hd_buy_potential,
       COUNT(*) AS return_count,
       AVG(cr.cr_net_loss) AS avg_net_loss,
       SUM(cr.cr_net_loss) AS total_net_loss,
       CASE WHEN SUM(cr.cr_net_loss) > 30000 THEN 'Extreme'
            WHEN SUM(cr.cr_net_loss) > 15000 THEN 'Very High'
            WHEN SUM(cr.cr_net_loss) > 5000 THEN 'High'
            ELSE 'Low' END AS loss_category,
       ROW_NUMBER() OVER (PARTITION BY sm.sm_type ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_rank_by_type
FROM catalog_returns cr
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
WHERE td.t_hour BETWEEN 8 AND 20
GROUP BY sm.sm_type, sm.sm_carrier, td.t_hour, hd_ret.hd_buy_potential
HAVING SUM(cr.cr_net_loss) > 2000
ORDER BY loss_rank_by_type
LIMIT 10
