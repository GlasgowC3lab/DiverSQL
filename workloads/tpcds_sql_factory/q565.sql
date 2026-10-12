SELECT sm.sm_type,
       sm.sm_carrier,
       td.t_hour,
       hd_ret.hd_buy_potential,
       SUM(cr.cr_net_loss) AS total_net_loss,
       SUM(cr.cr_fee) AS total_fee,
       CASE WHEN SUM(cr.cr_net_loss) > 22000 THEN 'Very High'
            WHEN SUM(cr.cr_net_loss) > 11000 THEN 'High'
            ELSE 'Medium' END AS loss_category,
       RANK() OVER (PARTITION BY sm.sm_type ORDER BY SUM(cr.cr_net_loss) DESC) AS type_rank,
       ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_fee) DESC) AS fee_rank
FROM catalog_returns cr
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
WHERE td.t_am_pm = 'PM'
GROUP BY sm.sm_type, sm.sm_carrier, td.t_hour, hd_ret.hd_buy_potential
HAVING SUM(cr.cr_fee) > 500
ORDER BY type_rank, fee_rank
