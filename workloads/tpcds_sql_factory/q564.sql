SELECT sm.sm_type,
       sm.sm_carrier,
       td.t_meal_time,
       hd_ret.hd_buy_potential,
       SUM(cr.cr_net_loss) AS total_net_loss,
       COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
       PERCENT_RANK() OVER (ORDER BY SUM(cr.cr_net_loss)) AS loss_percentile,
       CASE WHEN SUM(cr.cr_net_loss) > 18000 THEN 'Severe'
            WHEN SUM(cr.cr_net_loss) > 9000 THEN 'High'
            ELSE 'Normal' END AS loss_category
FROM catalog_returns cr
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
WHERE cr.cr_return_quantity > 1
GROUP BY sm.sm_type, sm.sm_carrier, td.t_meal_time, hd_ret.hd_buy_potential
HAVING COUNT(*) > 50
ORDER BY total_net_loss DESC
LIMIT 7
