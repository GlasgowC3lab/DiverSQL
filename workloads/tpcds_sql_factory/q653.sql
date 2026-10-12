SELECT sm.sm_type,
       sm.sm_carrier,
       td.t_meal_time,
       hd_ret.hd_buy_potential,
       SUM(cr.cr_net_loss) AS total_net_loss,
       AVG(cr.cr_return_quantity) AS avg_return_qty,
       COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
       ROW_NUMBER() OVER (PARTITION BY sm.sm_type ORDER BY SUM(cr.cr_net_loss) DESC) AS rn,
       CASE WHEN SUM(cr.cr_net_loss) > 20000 THEN 'Critical'
            WHEN SUM(cr.cr_net_loss) > 12000 THEN 'Elevated'
            ELSE 'Low' END AS loss_category
FROM catalog_returns cr
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
WHERE cr.cr_return_quantity BETWEEN 2 AND 5
GROUP BY sm.sm_type, sm.sm_carrier, td.t_meal_time, hd_ret.hd_buy_potential
HAVING SUM(cr.cr_net_loss) > 5000
ORDER BY avg_return_qty ASC, total_net_loss DESC
LIMIT 10
